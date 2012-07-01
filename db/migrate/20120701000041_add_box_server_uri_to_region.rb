class AddBoxServerUriToRegion < ActiveRecord::Migration
  def change
    add_column :regions, :box_server_uri, :string
  end
end