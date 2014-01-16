class RegionSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :state, :ssl_enabled
end
