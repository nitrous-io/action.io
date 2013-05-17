class CreateCollaborationInvites < ActiveRecord::Migration
  def change
    create_table :collaboration_invites do |t|
      t.column      :email, :string, null: false
      t.column      :state, :string, default: 'activated', null: false
      t.column      :accepted_at, :datetime
      t.column      :last_reminded_at, :datetime
      t.references  :box

      t.timestamps
    end
  end
end
