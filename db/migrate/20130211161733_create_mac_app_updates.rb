class CreateMacAppUpdates < ActiveRecord::Migration
  def change
    create_table :mac_app_updates do |t|
      t.string :version, null: false
      t.string :title, null: false
      t.text :release_notes, null: false
      t.string :url, null: false
      t.integer :file_size, default: 0, null: false
      t.datetime :published_at

      t.timestamps
    end
  end
end
