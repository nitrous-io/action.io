class CreateUserProfiles < ActiveRecord::Migration
  def change
    create_table :user_profiles do |t|
      t.references :user, null: false
      t.boolean :subscribed_to_newsletter, default: true

      t.timestamps
    end
    add_index :user_profiles, :user_id
  end
end
