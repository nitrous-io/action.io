class BoxSerializer < ActiveModel::Serializer
  attributes :id, :name, :host, :state, :box_template_id, :owner_id, :region_id, :port, :box_server_uri, :container_name, :backend_not_available?
end
