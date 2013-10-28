class AddAuthToBox < ActiveRecord::Migration
  def change
    add_column :boxes, :auth_username, :string
    add_column :boxes, :auth_password, :string
  end
end
