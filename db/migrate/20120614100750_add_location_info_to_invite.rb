class AddLocationInfoToInvite < ActiveRecord::Migration
  def change
    add_column :invites, :ip, :string
    add_column :invites, :city, :string
    add_column :invites, :country, :string
    add_column :invites, :country_code, :string
    add_column :invites, :latitude, :float8
    add_column :invites, :longitude, :float8
  end
end