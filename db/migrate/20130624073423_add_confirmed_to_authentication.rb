class AddConfirmedToAuthentication < ActiveRecord::Migration
  def change
    add_column :authentications, :confirmed, :boolean, null: false, default: false
  end
end
