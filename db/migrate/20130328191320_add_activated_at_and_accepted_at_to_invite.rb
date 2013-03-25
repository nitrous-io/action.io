class AddActivatedAtAndAcceptedAtToInvite < ActiveRecord::Migration
  def change
    add_column :invites, :activated_at, :datetime
    add_column :invites, :accepted_at,  :datetime
  end
end
