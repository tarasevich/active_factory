class ActiveFactory::Define
  factory :user, :class => User do
    email { "user#{i}@tut.by" }
    password { "password#{i}#{i}" }
  end

  factory :post do
    text { "TTT#{index}" }
  end

  factory :simple_user, :class => User do
    email "simple_user@gmail.com"
    password "simple_password"
  end

  factory :post_with_after_build, :class => Post do
    text "YYY"
    after_build { object.text = "ZZZ" }
  end

  factory :post_overrides_method, :class => Post do
    text "XXX"
  end

  factory :follower, :class => User do
    prefer_associations :following
  end
end
