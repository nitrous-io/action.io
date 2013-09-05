class BillingProfileSerializer < ActiveModel::Serializer
  attributes :id, :formatted_card_number, :card_type, :active
  has_many :subscriptions
end
