class AddAddonFeatures < ActiveRecord::Migration
  def change
    create_table :addon_features do |t|
      t.references :addon
      t.string :name, null: false
      t.string :icon
      t.text :description

      t.timestamps
    end
  end
end
