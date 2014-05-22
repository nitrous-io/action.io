class BoxhostPlanSerializer < ActiveModel::Serializer
  attributes :id, :name, :price, :interval, :memory, :storage, :box_limit,
    :display_order, :features
end
