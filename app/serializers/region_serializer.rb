class RegionSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :state, :label
end
