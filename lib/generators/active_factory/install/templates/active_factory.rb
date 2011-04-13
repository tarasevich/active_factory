require 'active_factory'

RSpec::configure do |config|
  config.include ActiveFactory::API, :type => :controller
  config.include ActiveFactory::API, :type => :model
  config.include ActiveFactory::API, :type => :request
end

require File.expand_path "../../define_factories", __FILE__