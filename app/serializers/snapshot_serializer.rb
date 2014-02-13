class SnapshotSerializer < ActiveModel::Serializer
  attributes :id, :name, :user_id, :box_id, :state, :created_at, :completed_at
end
