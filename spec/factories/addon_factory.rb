FactoryGirl.define do
  factory :addon do
    sequence(:uid)                  { |n| "uid-#{n}" }

    config_vars                     { ["var_1", "var_2"] }
    required_vars                   { { "var" => "var prompt" } }

    sequence(:production_base_url)  { |n| "https://production-#{n}.test/aio/resources" }
    sequence(:production_sso_url)   { |n| "https://production-#{n}.test/sso/login" }
    sequence(:test_base_url)        { |n| "https://test-#{n}.test/aio/resources" }
    sequence(:test_sso_url)         { |n| "https://test-#{n}.test/sso/login" }

    sequence(:password)             { |n| "password-#{n}" }
    sequence(:sso_salt)             { |n| "sso-salt-#{n}" }
    association :owner,             factory: :user
  end
end

