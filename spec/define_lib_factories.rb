class ActiveFactory::Define
  # model class will be inferred from factory name: User
  # i - refers to an index of the instance
  factory :user do
    email { "user#{i}@tut.by" }
    password { "password#{i}#{i}" }
  end

  factory :post, :class => Post do
    text { "Content #{index}" }
  end

  factory :simple_user, :class => User do
    email "simple_user@gmail.com"
    password "simple_password"
  end

  factory :post_with_after_build, :class => Post do
    text "Post with after_build"
    after_build { model.text = "After Build #{i}" }
  end

  factory :post_overrides_method, :class => Post do
    text "Post overrides a method"
  end

  factory :follower, :class => User do
    prefer_associations :following
  end
end
