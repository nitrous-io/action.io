class BoxSerializer < ActiveModel::Serializer
  attributes :id, :name, :host, :state,
             :memory, :storage, :cpu_multiplier, :virtual_memory, :n2o_cost,
             :expected_cpu_multiplier, :expected_virtual_memory,
             :version, :box_template_id, :owner_id, :region_id, :port,
             :source_snapshot_id, :box_server_uri, :container_name,
             :auth_username, :auth_password, :backend_available?, :force_shutdown?,
             :custom_domain
end
