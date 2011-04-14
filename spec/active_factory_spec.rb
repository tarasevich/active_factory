require 'support/active_record_environment'
require 'active_factory'
require "#{File.dirname(__FILE__)}/spec_helper"
require "#{File.dirname(__FILE__)}/define_lib_factories"

describe "ActiveFactory" do
  include ActiveFactory::API
  include Test::Unit::Assertions
  include ActiveRecordEnvironment

  before(:each) do
    empty_database!
  end

# INTRODUCING METHODS

  it "defines methods to access singleton object, singleton hash, collection and collection of hashes" do
    models { user }

    respond_to?(:user).should == true
    respond_to?(:user_).should == true
    respond_to?(:users).should == true
    respond_to?(:users_).should == true

    respond_to?(:post).should == false
    respond_to?(:post_).should == false
    respond_to?(:posts).should == false
    respond_to?(:posts_).should == false
  end

  it "vice versa" do
    models { post }

    respond_to?(:post).should == true
    respond_to?(:user).should == false
  end

# CREATING IN MODELS SECTION

  it "creates singleton model without blocks and with explicit class" do
    models { simple_user }

    simple_user.email.should == "simple_user@gmail.com"
    simple_user.password.should == "simple_password"
    simple_user.should be_an_instance_of User
    simple_user.should_not be_new_record

    User.all.should == [simple_user]
  end

  it "creates singleton model 'user' with index and implicit class" do
    models { user }

    user.email.should == "user0@tut.by"
    user.password.should == "password00"

    user.should be_an_instance_of User
    user.should_not be_new_record

    User.all.should == [user]
  end

  it "creates a collection" do
    models { users(2) }

    users[0].email.should == "user0@tut.by"
    users[1].email.should == "user1@tut.by"
    users[1].password.should == "password11"

    users.size.should == 2
    User.all.should == users
  end

  it "collection(i) adds specified number of new instances to a collection" do
    models { users(1); users(2) }

    users[0].email.should == "user0@tut.by"
    users[1].email.should == "user1@tut.by"
    users[2].email.should == "user2@tut.by"

    users.size.should == 3
    User.all.should == users
  end

  it "collection() syntax allows to refer to all entities created by a factory" do
    models { users }

    users.size.should == 0
  end
  
  it "collection(1) syntax creates additional instance" do
    models { user; users(1) }

    users[0].email.should == "user0@tut.by"
    users[1].email.should == "user1@tut.by"

    users.size.should == 2
  end

  it "collection(1) syntax + singleton syntax" do
    models { users(1); user }

    assert User.find_by_email "user0@tut.by"
    User.find_by_email("user1@tut.by").should == nil
  end

  it "cannot use singleton syntax when many instances are created" do
    assert_raise RuntimeError do
      models { users(2); user }
    end
  end

# HASHES IN PRODUCE SECTION

  it "singleton syntax defines 'user_' method to access a hash" do
    models { user } #.define_all

    user_.should == {:email => "user0@tut.by", :password => "password00" }
    user.should be_an_instance_of User
  end

  it "declares hash without creating an object" do
    models { user_ }

    user_.should == {:email => "user0@tut.by", :password => "password00" }
    user.should == nil

    User.all.should == []
  end

  it "defines symbols 'users' and 'users_' for a collection" do
    models { users(1) } #.define_all

    users[0].email.should == "user0@tut.by"
    users_[0].email.should == "user0@tut.by"
    users[0].new_record?.should == false

    users.size.should == 1
    User.all.should == users
  end

  it "declares many hashes without creating" do
    models { posts_(2) }

    posts_[0].text.should == "Content 0"
    posts_[1].text.should == "Content 1"

    Post.all.should == []
  end

# LINKING
  
  it "associates through belongs_to" do
    models { post - user }

    post.user.should == user
    user.posts.should == post

    Post.all.should == [post]
    Post.all.map(&:user).should == [user]
  end

  it "associates through has_many" do
    models { user - post }

    post.user.should == user
    user.posts.should == post

    User.all.should == [user]
    User.all.map(&:posts).should == [[post]]
  end

  it "associates singleton and collection" do
    models { user - posts(2) }

    user.posts.should == posts
    posts.map(&:user).should == [user, user]

    User.all.should == [user]
    User.all.map(&:posts).should == [posts]
  end

  it "associates collections" do
    models { posts(3) - users(1) }

    posts = 3.times.map { |n| Post.find_by_text("Content #{n}") }

    1.times { |n|
      user = User.find_by_email("user#{n}@tut.by")
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

    post_with_after_build.text.should == "After Build"
  end

  it "provides methods for hash keys" do
    models { post_with_after_builds(1) }

    post_with_after_builds_[0].text.should == "Post with after_build"
  end  

  it "syntax sugar to merge" do
    models { user_ }

    user_(:text => "new@email.com").should == user_.merge(:text => "new@email.com")
  end

  it "syntax sugar for update_attribute" do
    models { simple_user(:email => "modified@email.com") }

    simple_user.email.should == "modified@email.com"
  end

  it "syntax sugar for update_attribute for multiple instances" do
    models { simple_users({:email => "1st@email.com"}, {:email => "2nd@email.com"})}

    simple_users.size.should == 2
    simple_users[0].email.should == "1st@email.com"
    simple_users[1].email.should == "2nd@email.com"
  end

# MORE

  it "leaves no coincidental methods in following specs" do
    models { post_overrides_method }

    assert_raise(NameError) { simple_user }
    assert_raise(NameError) { simple_user_ }
    assert_raise(NameError) { simple_users }
    assert_raise(NameError) { simple_users_ }
    assert_raise(NameError) { post }
  end

  def post_overrides_method_; "invoke function" end

  it "preserves old methods" do
    post_overrides_method_.should == "invoke function"
  end

  it "#factory_attributes returns attributes" do
    assert_equal({:text => "Content 1"}, self.class.class_eval { factory_attributes(:post, 1) })
  end

  it "::Define.models[:user] is model" do
    factory = ActiveFactory::Define.factories_hash[:user]

    assert factory
    factory.model_class.should == User
  end
end
