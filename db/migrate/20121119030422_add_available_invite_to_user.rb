class AddAvailableInviteToUser < ActiveRecord::Migration
  def change
    add_column :users, :available_invite, :integer, default: 0, null: false
  end
end
