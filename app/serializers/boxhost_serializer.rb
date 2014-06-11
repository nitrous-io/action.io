class BoxhostSerializer < ActiveModel::Serializer
  attributes :id, :name, :state, :owner_id, :region_id, :boxhost_plan_id
end
