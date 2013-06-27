class AddIntroSeenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :intro_seen, :boolean, default: false, null: false
  end
end
