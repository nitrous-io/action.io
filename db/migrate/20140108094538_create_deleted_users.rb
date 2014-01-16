class CreateDeletedUsers < ActiveRecord::Migration
  def change
    create_table :deleted_users do |t|
      t.integer   :user_id
      t.string    :email
      t.string    :username
      t.datetime  :created_at
      t.datetime  :deleted_at
    end
    add_index :deleted_users, :user_id
    add_index :deleted_users, :email
  end
end
