class BoxSerializer < ActiveModel::Serializer
  attributes :id, :name, :host, :state, :box_template_id, :owner_id, :region_id, :port, :box_server_uri

  def box_server_uri
    ENV['ACTION_BOX_SERVER_URI']
  end
end
