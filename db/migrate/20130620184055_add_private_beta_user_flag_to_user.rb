class AddPrivateBetaUserFlagToUser < ActiveRecord::Migration
  def up
    add_column :users, :in_private_beta, :boolean, default: false, null: false
    # When we run this migration, all existing users in the database
    # will be considered to be part of the private beta
    User.update_all(in_private_beta: true)
  end

  def down
    remove_column :users, :in_private_beta
  end
end
