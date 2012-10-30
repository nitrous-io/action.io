class BoxTemplateSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :enabled, :runtime
end
