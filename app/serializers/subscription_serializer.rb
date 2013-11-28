class SubscriptionSerializer < ActiveModel::Serializer
  attributes :state
  has_one :plan
end
