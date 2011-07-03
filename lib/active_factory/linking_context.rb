module ActiveFactory

  # provides methods that refer models in models {} block
  class LinkingContext
    def initialize model_names, containers_hash, context
      @context = context
      h = containers_hash

      obj_class_eval do
        model_names.each { |name|

          define_method name do |*args|
            not args.many? or raise "0 or 1 arguments expected, got: #{args.inspect}"
            args.none? or args[0].is_a?(Hash) or raise "an argument must be a Hash for a singleton model "

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

end