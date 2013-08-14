class AddAddonCategories < ActiveRecord::Migration
  def change
    create_table :addon_categories do |t|
      t.string :name, null: false
      t.string :icon, null: false
      t.text :description
      t.timestamps
    end

    # addon belongs to addon category
    add_column :addons, :addon_category_id, :integer
    add_index :addons, :addon_category_id
  end
end
