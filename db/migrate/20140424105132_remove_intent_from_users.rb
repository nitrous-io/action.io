class RemoveIntentFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :intent
  end
end
