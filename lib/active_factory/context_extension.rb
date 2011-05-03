module ActiveFactory

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