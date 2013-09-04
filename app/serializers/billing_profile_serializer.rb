class BillingProfileSerializer < ActiveModel::Serializer
  attributes :id, :formatted_card_number, :card_type
  has_many :subscriptions
end
