class CreateBonuses < ActiveRecord::Migration
  def change
    create_table :bonuses do |t|
      t.references :user, null: false

      t.datetime :invite_friends
      t.datetime :github
      t.datetime :google
      t.datetime :twitter
      t.datetime :facebook
      t.datetime :linkedin

      t.timestamps
    end
    add_index :bonuses, :user_id
  end
end
