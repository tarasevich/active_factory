require 'hash_struct'

module ActiveFactory
  # should be included in specs
  module API
    extend ActiveSupport::Concern

    included do
      attr_accessor :_active_factory_context_extension

      after do
        _active_factory_context_extension.try :undo
        self._active_factory_context_extension = nil
      end
    end

    module ClassMethods
      def factory_attributes model_name, index = 0
        Define.
            factories_hash[model_name].
            attributes_for(index)
      end
    end

    # methods available in specs
    module InstanceMethods
      def models &define_graph
        not _active_factory_context_extension or raise "cannot use models twice in an example"

        context = self
        factories_hash = Define.factories_hash
        containers_hash = Hash.new { |this, name|
          factory = factories_hash[name]
          this[name] = Container.new(name, factory, context)
        }
        linking_context = LinkingContext.new factories_hash.keys, containers_hash, context
        self._active_factory_context_extension = ContextExtension.new

        linking_context.instance_eval &define_graph
        containers_hash.values.each &:before_save
        containers_hash.values.each &:save
        _active_factory_context_extension.extend_test_context containers_hash, context
        nil
      end
    end
  end

  class FactoryDSL
    def initialize
      @attribute_expressions = {}
    end

    def prefer_associations *assoc_symbols
      @prefer_associations = assoc_symbols
    end

    def after_build &callback
      @after_build = callback
    end

    def before_save &callback
      @before_save = callback
    end

    def method_missing method, *args, &expression
      if args.many? or args.any? and block_given?
        raise "should be either block or value: #{method} #{args.inspect[1..-2]}"
      end
      @attribute_expressions[method.to_sym] = expression || proc { args[0] }
    end
  end

  # the class that should be "extended" to define models
  class Define
    @@factories = {}

    def self.factory name, options = {}, &block
      model_class = options[:class]
      if parent_sym = options[:parent]
        parent = @@factories[parent_sym] or raise "undefined parent factory #{parent_sym}"
      end
      
      @@factories[name] = FactoryDSL.new.instance_eval {
        instance_eval(&block)
        Factory.new name, parent, model_class,
          @prefer_associations, @attribute_expressions, @after_build, @before_save
      }
    end

    def self.factories_hash
      @@factories
    end
  end

  # defines methods that can be used in a model definition
  # model - the model under construction
  # index - index of the model in the factory
  # context - spec context where the models {} block was evaluated
  class CreationContext < Struct.new :index, :context, :model
    alias i index
  end

  # creates instances of the given model class
  class Factory < Struct.new :name, :parent, :model_class,
                             :prefer_associations, :attribute_expressions, :after_build, :before_save
    def initialize name, parent, *overridable
      @overridable = parent ? parent.merge_overridable(overridable) : overridable
      super(name, parent, *@overridable)
      self.attribute_expressions = 
        parent.attribute_expressions.merge(self.attribute_expressions) if parent
      
      name.is_a? Symbol or raise "factory name #{name.inspect} must be symbol"
      self.model_class ||= Kernel.const_get(name.to_s.capitalize)
    end
    
    def merge_overridable overridable
      overridable.zip(@overridable).
      map { |his, my| his or my }
    end
    
    def attributes_for index
      context = CreationContext.new(index)
      attrs = attribute_expressions.map { |a, e| [a, context.instance_eval(&e)] }
      Hash[attrs]
    end

    def apply_after_build index, context, model
      if after_build
        CreationContext.new(index, context, model).
            instance_eval(&after_build)
      end
    end

    def apply_before_save index, context, model
      if before_save
        CreationContext.new(index, context, model).
            instance_eval(&before_save)
      end
    end
  end

  class ContainerEntry
    attr_reader :model, :attrs

    def initialize index, factory, context
      @index = index
      @factory = factory
      @attrs = HashStruct[factory.attributes_for(index)]
      @context = context
    end

    def merge hash
      @attrs = @attrs.merge hash
    end

    def build
      unless @model
        @model = @factory.model_class.new
        @attrs.each_pair { |k,v| @model.send "#{k}=", v }

        @factory.apply_after_build @index, @context, @model
      end
    end

    def before_save
      if @model and not @saved
        @factory.apply_before_save @index, @context, @model
      end
    end

    def save
      if @model and not @saved
        @model.save!
        @saved = true
      end
    end
  end

  # keeps collection of created instances of the given model class
  class Container
    attr_accessor :entries
    attr_reader :name, :factory

    def initialize name, factory, context
      @name = name
      @factory = factory
      @context = context
      @entries = [].freeze
    end

    def create count
      dup_with add_entries count
    end

    def singleton
      if @entries.none?
        add_entries 1
      elsif @entries.many?
        raise "Multiple instances were declared for model :#{@name}."+
              "Use <#{@name.to_s.pluralize}> to access them"
      end
      self
    end

    def zip_merge *hashes
      @entries.size == hashes.size or raise

      @entries.zip(hashes) { |entry, hash|
        entry.merge hash
      }
      self
    end

    def build
      @entries.each &:build
      self
    end

    def make_linker
      Linker.new self
    end

    def before_save
      @entries.each &:before_save
    end

    def save
      @entries.each &:save
    end

    def attrs
      @entries.map &:attrs
    end

    def objects
      @entries.map &:model
    end

    private

    def dup_with entries
      that = clone
      that.entries = entries
      that
    end

    def add_entries count
      size = @entries.size
      added = (size...size+count).
          map { |i| ContainerEntry.new i, factory, @context }
      @entries = (@entries + added).freeze
      added
    end
  end

  # provides syntax to create associations between models
  class Linker
    def initialize container, use_association = nil
      @container = container
      @use_association = use_association

      @entries = container.entries
      @model_class = container.factory.model_class
      @prefer_associations = container.factory.prefer_associations
    end

    attr_accessor :entries, :model_class

    def - that
      case that
        when Linker
          associate that
          that
        when Symbol
          Linker.new @container, that
        else
          raise "cannot associate with #{that.inspect}"
      end
    end

    private

    def associate linker
      ar = get_association linker.model_class

      case ar.macro
        when :has_many, :has_and_belongs_to_many
          assoc_entries = proc { |e, e2|
            e.model.send(ar.name) << e2.model
          }

          if entries.one? or linker.entries.one?
            entries.each { |e|
              linker.entries.each { |e2|
                assoc_entries[e, e2]
              }
            }

          elsif entries.size == linker.entries.size
            entries.zip(linker.entries) { |e, e2|
              assoc_entries[e, e2]
            }

          else
            raise "when linking models, they should be one of this: 1-n, n-1, n-n (e.i. equal number)"
          end

        when :belongs_to, :has_one
          assoc_entries = proc { |e, e2|
            e.model.send :"#{ar.name}=", e2.model
          }

          if linker.entries.one?
            entries.each { |e|
              assoc_entries[e, linker.entries.first]
            }

          elsif entries.size == linker.entries.size
            entries.zip(linker.entries) { |e, e2|
              assoc_entries[e, e2]
            }

          else
            raise "exactly one instance of an object should be assigned to belongs_to association: #{@container.name} - #{linker.instance_variable_get(:@container).try :name}"
          end
      end
    end

    def get_association with_class
      if @use_association
        @model_class.reflect_on_association(@use_association) or
          raise "No association #{@use_association.inspect} found for #{@model_class}"
      else
        find_association with_class
      end
    end

    def find_association with_class
      assocs = @model_class.reflect_on_all_associations.find_all { |assoc|
        assoc.class_name == with_class.name
      }

      if assocs.none?
        raise "Trying to link, but no association found from #{@model_class} to #{with_class}"

      elsif assocs.one?
        assocs.first

      elsif assocs.many?
        resolved = assocs.select { |assoc| @prefer_associations.member? assoc.name }
        resolved.one? or
            raise "Ambiguous associations: #{assocs.map(&:name).inspect} of #{@model_class} to #{with_class}. prefer_associations=#{@prefer_associations.inspect}"

        resolved.first
      end
    end

  end

  # provides methods that refer models in models {} block
  class LinkingContext
    def initialize model_names, containers_hash, context
      @context = context
      h = containers_hash

      obj_class_eval do
        model_names.each { |name|

          define_method name do |*args|
            not args.many? or raise "0 or 1 arguments expected, got: #{args.inspect}"

            if args.none?
              h[name].singleton
            else
              h[name].singleton.zip_merge(args[0])

            end.build.make_linker
          end

          define_method :"#{name.to_s.pluralize}" do |*args|

            if args.none?
              h[name]

            elsif args[0].is_a? Fixnum and args.one?
              h[name].create(args[0])

            elsif args.all? { |arg| arg.is_a? Hash }
              h[name].create(args.size).zip_merge(*args)

            else
              raise "expected no args, or single integer, or several hashes, got: #{args.inspect}"

            end.build.make_linker
          end

          define_method :"#{name}_" do
            h[name].singleton.make_linker
          end

          define_method :"#{name.to_s.pluralize}_" do |count|
            h[name].create(count).make_linker
          end
        }
      end
    end

    private

    def obj_class_eval &block
      class << self
        self
      end.class_eval &block
    end

    def method_missing *args, &block
      if block
        @context.send *args, &block
      else
        @context.send *args
      end
    end
  end

  # introduces models' names in a spec's context
  class ContextExtension
    def undo
      @undo_define_methods[] if @undo_define_methods
      @undo_define_methods = nil
    end

    def extend_test_context containers_hash, context
      mrg = proc {|args, hash|
        if args.none?
          hash
        elsif args.one? and args[0].is_a? Hash
          hash.merge args[0]
        else
          raise "Only has is valid argument, but *args=#{args.inspect}"
        end
      }

      method_defs =
          containers_hash.map { |name, container| [
              name, proc { container.singleton.objects[0] },
              :"#{name}_", proc { |*args| mrg[args, container.singleton.attrs[0]] },
              :"#{name.to_s.pluralize}", proc { container.objects },
              :"#{name.to_s.pluralize}_", proc { container.attrs }
          ] }.
              flatten.each_slice(2)

      @undo_define_methods =
          define_methods_with_undo context, method_defs
    end

    private

    def define_methods_with_undo model, method_defs
      old_methods = model.methods.map &:to_sym

      overridden_methods, new_methods =
          method_defs.
              map(&:first).
              partition { |name| old_methods.include? name.to_sym }

      overridden_methods.map! { |name| [name, model.method(name)] }

      define_method, undef_method = class << model
        [method(:define_method), method(:undef_method)]
      end

      method_defs.each{ |n,b| define_method[n,b] }

      lambda {
        overridden_methods.each{ |n,b| define_method[n,b] }
        new_methods.each &undef_method
      }
    end
  end
end