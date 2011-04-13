require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter  => "sqlite3",
  :database => ":memory:"
)

ActiveRecord::Schema.define(:version => 0) do
  create_table "posts", :force => true do |t|
    t.text     "text"
    t.integer  "user_id"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                               :default => "", :null => false
  end

  create_table "following", :force => true, :id => false do |t|
    t.integer   "following_id"
    t.integer   "follower_id"
  end

end

class User < ActiveRecord::Base
  has_many :posts
  has_and_belongs_to_many :followers, :class_name => 'User', :foreign_key => 'following_id', :join_table => 'following'
  has_and_belongs_to_many :following, :class_name => 'User', :foreign_key => 'follower_id', :join_table => 'following'
  attr_accessor :password
end

class Post < ActiveRecord::Base
  belongs_to :user
end

module ActiveRecordEnvironment

  def empty_database!
    [User, Post].each do |klass|
      klass.delete_all
    end
  end

end
