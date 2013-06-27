class RemoveInviteCodeFromUsers < ActiveRecord::Migration
  def up
    remove_column :users, :invite_code
  end

  def down
    add_column :users, :invite_code, :string
  end
end
