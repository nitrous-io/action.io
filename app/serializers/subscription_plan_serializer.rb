class SubscriptionPlanSerializer < ActiveModel::Serializer
  attributes :id, :name, :price, :interval, :features, :highlight, :display_order, :n2o_amount, :cpu_shares_multiplier, :virtual_memory_multiplier
end
