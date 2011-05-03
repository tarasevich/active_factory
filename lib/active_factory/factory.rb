module ActiveFactory
  # creates instances of the given model class
  class Factory < Struct.new :name, :parent, :model_class,
                             :prefer_associations, :attribute_expressions, :after_build, :before_save
    def initialize name, parent, *overridable
      @overridable = parent ? parent.merge_overridable(overridable) : overridable
      super(name, parent, *@overridable)
      self.attribute_expressions =
        parent.attribute_expressions.merge(self.attribute_expressions) if parent

      name.is_a? Symbol or raise "factory name #{name.inspect} must be symbol"
      self.model_class ||=
          (@overridable[0] = name.to_s.camelize.constantize)
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

  # defines methods that can be used in a model definition
  # model - the model under construction
  # index - index of the model in the factory
  # context - spec context where the models {} block was evaluated
  class CreationContext < Struct.new :index, :context, :model
    alias i index
  end
end