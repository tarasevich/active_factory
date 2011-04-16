require 'support/active_record_environment'
require 'active_factory'
require "#{File.dirname(__FILE__)}/spec_helper"
require "#{File.dirname(__FILE__)}/define_lib_factories"

describe ActiveFactory::Define do
  include ActiveFactory::API
  include Test::Unit::Assertions
  include ActiveRecordEnvironment

  before(:each) do
    empty_database!
  end

  describe "Processes factory definitions:" do

    def get_factory name
      ActiveFactory::Define.factories_hash[name]
    end

    it "with explicit class and explicit values for attributes" do
      factory = get_factory :simple_user
      factory.model_class.should == User
      factory.after_build.should == nil
      factory.prefer_associations.should == nil
      factory.attributes_for(0).should ==
          {:email => 'simple_user@gmail.com',
           :password => 'simple_password'}
    end

    it "with implicit class and blocks for attributes" do
      factory = get_factory :user
      factory.model_class.should == User
      factory.after_build.should == nil
      factory.prefer_associations.should == nil
      factory.attributes_for(0).should ==
          {:email => 'user0@tut.by',
           :password => 'password00'}
      factory.attributes_for(1).should ==
          {:email => 'user1@tut.by',
           :password => 'password11'}
    end

    it "with explicit class and blocks for attributes" do
      factory = get_factory :post
      factory.model_class.should == Post
      factory.after_build.should == nil
      factory.prefer_associations.should == nil
      factory.attributes_for(0).should ==
          {:text => "Content 0"}
    end

    it "with after_build block" do
      factory = get_factory :post_with_after_build
      factory.model_class.should == Post
      factory.after_build.should be_an_instance_of Proc
      factory.prefer_associations.should == nil
      factory.attributes_for(0).should ==
          {:text => "Post with after_build"}

      post = mock "Post"
      post.should_receive(:text=).with("After Build 0").and_return(nil)
      factory.apply_after_build 0, nil, post
    end

    it "with before_save block" do
      factory = get_factory :post_with_before_save
      factory.model_class.should == Post
      factory.before_save.should be_an_instance_of Proc
      factory.prefer_associations.should == nil
      factory.attributes_for(0).should ==
          {:text => "Post with before_save"}

      post = mock "Post"
      post.should_receive(:text=).with("Before Save 0").and_return(nil)
      factory.apply_before_save 0, nil, post
    end

    it "with preferred associations" do
      factory = get_factory :follower
      factory.prefer_associations.should == [:following]
    end
  end
end
