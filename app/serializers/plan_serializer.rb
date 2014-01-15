class PlanSerializer < ActiveModel::Serializer
  attributes :id, :name, :price, :interval, :features, :highlight, :display_order, :n2o_amount, :cpu_multiplier, :vmem_multiplier, :memory, :storage
end
