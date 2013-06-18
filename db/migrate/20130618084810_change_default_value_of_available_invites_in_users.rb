class ChangeDefaultValueOfAvailableInvitesInUsers < ActiveRecord::Migration
  def up
    change_column :users, :available_invites, :integer, default: 10
    User.update_all(available_invites: 10)
  end

  def down
    change_column :users, :available_invites, :integer, default: 0
  end
end
