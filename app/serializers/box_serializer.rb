class BoxSerializer < ActiveModel::Serializer
  attributes :id, :name, :host, :state, :memory, :storage, :version, :box_template_id, :owner_id, :region_id, :port, :box_server_uri, :container_name, :backend_available?
end
