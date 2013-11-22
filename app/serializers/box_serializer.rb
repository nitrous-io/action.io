class BoxSerializer < ActiveModel::Serializer
  attributes :id, :name, :host, :state, :memory, :storage, :cpu_multiplier,
             :version, :box_template_id, :owner_id, :region_id, :port,
             :box_server_uri, :container_name, :backend_available?,
             :auth_username, :auth_password
end
