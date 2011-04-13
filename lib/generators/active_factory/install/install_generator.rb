module ActiveFactory
  module Generators #:nodoc:
    class InstallGenerator < Rails::Generators::Base #:nodoc:
      source_root File.expand_path('../templates', __FILE__)

      def define_factories_file
        copy_file "define_factories.rb", "spec/define_factories.rb"
      end

      def active_factory_file
        copy_file "active_factory.rb", "spec/support/active_factory.rb"
      end
    end
  end
end