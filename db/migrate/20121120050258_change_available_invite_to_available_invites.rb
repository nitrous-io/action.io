class ChangeAvailableInviteToAvailableInvites < ActiveRecord::Migration
  def change
    rename_column :users, :available_invite, :available_invites
  end
end
