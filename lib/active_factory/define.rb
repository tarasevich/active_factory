module ActiveFactory
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
end