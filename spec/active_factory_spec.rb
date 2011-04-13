require 'support/active_record_environment'
require 'active_factory'
require "#{File.dirname(__FILE__)}/spec_helper"
require "#{File.dirname(__FILE__)}/define_lib_factories"

describe "models {}" do
  include ActiveFactory::API
  include Test::Unit::Assertions
  include ActiveRecordEnvironment

  before(:each) do
    empty_database!
  end
    
# BASIC

  it "creates model :duplicated_post" do
    models { duplicated_post }

    assert Post.find_by_text "TTT"
  end

  it "creates model :duplicated_user" do
    models { duplicated_user }

    assert User.find_by_email "xxx@tut.by"
  end

  it "::Define.models[:duplicated_user] is model" do
    factory = ActiveFactory::Define.factories_hash[:duplicated_user]

    assert factory
    factory.model_class.should == User
    factory.attribute_expressions[:email].call.should == "xxx@tut.by"
    User.create! factory.attributes_for(0)
  end

# CREATING IN PRODUCE SECTION

  it "defines symbol :duplicated_user for singleton" do
    models { duplicated_user } #.define_all

    assert_instance_of User, duplicated_user
    duplicated_user.email.should == "xxx@tut.by"
    duplicated_user.new_record?.should == false
  end

  it "defines symbol :users for collection" do
    models { users(1) } #.define_all

    users[0].email.should == "yyy0@tut.by"
    users_[0].email.should == "yyy0@tut.by"
    users[0].new_record?.should == false
  end

  it "creates collection" do
    models { users(2) }

    assert User.find_by_email("yyy0@tut.by")
    assert User.find_by_email("yyy1@tut.by")
    User.find_by_email("yyy2@tut.by").should == nil
  end

  it "creates twice for s() syntax" do
    models { users(1); users(1) }

    assert User.find_by_email "yyy0@tut.by"
    assert User.find_by_email "yyy1@tut.by"
  end

  it "allows to refer to all entities in models{} block" do
    models { users }
  end
  
  it "plural s() syntax creates additional instance" do
    models { user; users(1) }

    assert User.find_by_email "yyy0@tut.by"
    assert User.find_by_email "yyy1@tut.by"
  end

  it "creates once for s() + singleton" do
    models { users(1); user }

    assert User.find_by_email "yyy0@tut.by"
    User.find_by_email("yyy1@tut.by").should == nil
  end

  it "fails with singleton for multiple" do
    assert_raise RuntimeError do
      models { users(2); user }
    end
  end

# HASHES IN PRODUCE SECTION

  it "defines symbol :duplicated_post_ for hash" do
    models { duplicated_post } #.define_all

    duplicated_post_.should == {:text => "TTT"}
  end

  it "declares hash without creating" do
    models { post_ }

    post_.text.should == "TTT0"
    Post.find_by_text("TTT0").should == nil
  end

  it "declares many hashes without creating" do
    models { posts_(2) }

    posts_[1].text.should == "TTT1"
    Post.find_by_text("TTT1").should == nil
  end

# LINKING
  
  it "associates through belongs_to" do
    models { duplicated_post - duplicated_user }

    Post.find_by_text("TTT").user.should == User.find_by_email("xxx@tut.by")
  end

  it "associates through has_many" do
    models { duplicated_user - duplicated_post }

    Post.find_by_text("TTT").user.should == User.find_by_email("xxx@tut.by")
  end

  it "associates single model and collection" do
    models { duplicated_user - posts(2) }

    user = User.find_by_email "xxx@tut.by"
    assert user
    user.posts.to_a.should == 2.times.map { |n| Post.find_by_text "TTT#{n}" }
  end

  it "associates collections" do
    models { posts(3) - users(1) }

    posts = 3.times.map { |n| Post.find_by_text("TTT#{n}") }

    1.times { |n|
      user = User.find_by_email("yyy#{n}@tut.by")
      assert user
      user.posts.all.should == posts
    }
  end

  it "zips links" do
    models { users(2) - posts(2) }

    2.times { |i|
      posts[i].user_id.should == users[i].id
    }
  end

  it "it associates only specified number of posts, not all" do
    models { posts(1); posts(1) - user } #.define_all

    assert posts[1].user
    posts[0].user.should == nil
  end

# ADVANCED FACTORY OPTIONS

  it "uses prefer_associations option" do
    models { follower - user }
    
    follower.following.should == [user]
  end

  it "allows to redefine prefer_associations" do
    models { follower - :followers - user }

    follower.followers.should == [user]
  end
  
  it "invokes after_create" do
    models { post_with_after_build } #.define_all

    post_with_after_build.text.should == "ZZZ"
  end

  it "provides methods for hash keys" do
    models { post_with_after_builds(1) }

    post_with_after_builds_[0].text.should == "YYY"
  end  

  it "syntax sugar to merge" do
    models { duplicated_user_ }

    duplicated_user_(:text => "new@email.com").should == duplicated_user_.merge(:text => "new@email.com")
  end

  it "syntax sugar for update_attribute" do
    models { duplicated_user(:email => "modified@email.com") }

    duplicated_user.email.should == "modified@email.com"
  end

  it "syntax sugar for update_attribute for multiple instances" do
    models { duplicated_users({:email => "1st@email.com"}, {:email => "2nd@email.com"})}

    duplicated_users.size.should == 2
    duplicated_users[0].email.should == "1st@email.com"
    duplicated_users[1].email.should == "2nd@email.com"
  end

# MORE

  it "leaves no coincidental methods in following specs" do
    models { post_overrides_method }

    assert_raise(NameError) { duplicated_user }
    assert_raise(NameError) { duplicated_user_ }
    assert_raise(NameError) { duplicated_users }
    assert_raise(NameError) { duplicated_users_ }
    assert_raise(NameError) { post }
  end

  def post_overrides_method_; "invoke function" end

  it "preserves old methods" do
    post_overrides_method_.should == "invoke function"
  end

  it "#factory_attributes returns attributes" do
    assert_equal({:text => "TTT1"}, self.class.class_eval { factory_attributes(:post, 1) })
  end

end
