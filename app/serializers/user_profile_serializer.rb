class UserProfileSerializer < ActiveModel::Serializer
  attributes :subscribed_to_monthly_newsletter, :subscribed_to_product_announcements
end
