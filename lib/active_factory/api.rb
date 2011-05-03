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
end