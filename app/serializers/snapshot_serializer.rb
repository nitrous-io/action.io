class SnapshotSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :url, :state, :box_id, :owner_id
end
