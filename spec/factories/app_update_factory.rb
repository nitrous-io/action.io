FactoryGirl.define do
  factory :app_update do
    sequence(:version) { |n| "#{n}.0.0" }
    sequence(:title) { |n| "version #{n}.0.0" }
    release_notes '* some bug fixes'
    file_size 40.megabytes
    sequence(:url) { |n| "http://s3.com/app#{n}.0.0.dmg" }
    published_at { Time.now }
  end
end
