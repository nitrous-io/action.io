class AddIntentToUsers < ActiveRecord::Migration
  def change
    add_column :users, :intent, :text
  end
end
