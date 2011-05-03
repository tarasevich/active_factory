module ActiveFactory

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
end