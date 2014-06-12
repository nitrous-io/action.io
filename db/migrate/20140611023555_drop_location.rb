class DropLocation < ActiveRecord::Migration
  def up
    drop_table :locations
    remove_column :boxhost_provider_templates, :location_id
    remove_column :boxhosts, :location_id
  end

  def down
    create_table :locations do |t|
      t.string :name
      t.string :description
      t.timestamps
    end

    add_column :boxhost_provider_templates, :location_id, :integer
    add_column :boxhosts, :location_id, :integer
  end
end
