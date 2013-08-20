class PlanSerializer < ActiveModel::Serializer
  attributes :id, :name, :price, :interval, :features, :hightlight, :display_order
end
