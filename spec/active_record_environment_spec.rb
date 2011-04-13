require "#{File.dirname(__FILE__)}/spec_helper"
require 'support/active_record_environment'

describe User do
  include ActiveRecordEnvironment

  before(:each) do
    empty_database!
  end

  it "can create user" do
    User.create!
  end
end 