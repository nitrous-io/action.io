class ChangeDefaultStateOfInviteAndRemoveActivatedAt < ActiveRecord::Migration
  def up
    change_column :invites, :state, :string, default: 'activated', null: false
    remove_column :invites, :activated_at
  end

  def down
    change_column :invites, :state, :string, default: 'pending', null: false
    add_column :invites, :activated_at, :datetime
  end
end
