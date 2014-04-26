class AddDeletedAtToUsers < ActiveRecord::Migration
  def up
    add_column :users, :deleted_at, :datetime

    remove_index :users, :email
    remove_index :users, :username

    add_index :users, [:email, :deleted_at], unique: true
    add_index :users, [:username, :deleted_at], unique: true
  end

  def down
    remove_index :users, [:email, :deleted_at]
    remove_index :users, [:username, :deleted_at]

    add_index :users, :email, unique: true
    add_index :users, :username, unique: true

    remove_column :users, :deleted_at
  end
end
