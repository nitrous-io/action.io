class BoxSerializer < ActiveModel::Serializer
  attributes :id, :name, :host, :state, :box_template_id, :owner_id, :region_id, :port
end
