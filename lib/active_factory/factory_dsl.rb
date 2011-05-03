module ActiveFactory
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
end