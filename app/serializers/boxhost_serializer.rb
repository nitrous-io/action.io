class BoxhostSerializer < ActiveModel::Serializer
  attributes :id, :name, :state, :dedicated, :owner_id, :location_id, :boxhost_plan_id
end
