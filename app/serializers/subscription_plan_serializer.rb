class SubscriptionPlanSerializer < ActiveModel::Serializer
  attributes :id, :name, :price, :interval, :features, :highlight, :display_order
end
