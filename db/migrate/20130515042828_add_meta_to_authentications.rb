class AddMetaToAuthentications < ActiveRecord::Migration
  def change
    add_column :authentications, :username, :string
    add_column :authentications, :meta, :text
  end
end
