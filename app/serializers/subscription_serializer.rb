class SubscriptionSerializer < ActiveModel::Serializer
  attributes :id, :state, :plan_id
end
