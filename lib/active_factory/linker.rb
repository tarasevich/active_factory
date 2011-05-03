module ActiveFactory

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
end