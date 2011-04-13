class ActiveFactory::Define
  factory :user, :class => User do
    email { "yyy#{i}@tut.by" }
    password { "matz#{i}#{i}" }
  end

  factory :post do
    text { "TTT#{index}" }
  end

  factory :duplicated_user, :class => User do
    email "xxx@tut.by"
    password "matz123"
  end

  factory :duplicated_post, :class => Post do
    text "TTT"
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
