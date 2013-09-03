class SubscriptionSerializer < ActiveModel::Serializer
  attributes :state
  has_one :subscription_plan
end
