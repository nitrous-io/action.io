class BoxTemplateSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :image, :enabled, :runtime
end
