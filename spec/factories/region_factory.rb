FactoryGirl.define do
  factory :region do
    sequence(:name)           { |n| "region-#{n}" }
    sequence(:description)    { |n| "Region #{n}" }
    sequence(:ami)            { |n| "ami-#{n}" }
    sequence(:box_server_uri) { |n| "https://box-server-uri-#{n}" }
    sequence(:keypair) { |n| "-----BEGIN RSA PRIVATE KEY-----\n#{n}\n-----END RSA PRIVATE KEY-----" }
  end
end
