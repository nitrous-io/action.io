class CreateInvites < ActiveRecord::Migration
  def change
    create_table :invites do |t|
      t.string  :email,   :null => false
      t.string  :invite_code
      t.string  :state,   :default => "pending", :null => false
      t.integer :inviting_user_id
      t.timestamps
    end
  end
end
