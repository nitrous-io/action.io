class AddLastRemindedAtToInvites < ActiveRecord::Migration
  def change
    add_column :invites, :last_reminded_at, :datetime
  end
end
