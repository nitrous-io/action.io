class AddAcceptedInvitesToUser < ActiveRecord::Migration
  def change
    add_column :users, :accepted_invites, :integer, default: 0, null: false
    User.update_all accepted_invites: 0
  end
end
