class CreateBoxhostsAndRelatedTables < ActiveRecord::Migration
  def change
    create_table :boxhosts do |t|
      t.string :name
      t.string :ip
      t.string :state, default: 'born', null: false
      t.boolean :dedicated, default: true
      t.datetime :terminated_at

      t.string :boxhost_provider
      t.string :boxhost_region

      t.integer :owner_id
      t.references :location
      t.references :boxhost_plan
      t.references :boxhost_provider_template

      t.timestamps
    end

    add_index :boxhosts, :owner_id

    create_table :boxhost_plans do |t|
      t.string :name
      t.integer :price
      t.string :interval
      t.integer :memory
      t.integer :storage
      t.integer :box_limit
      t.integer :display_order
      t.text :features
      t.timestamps
    end

    create_table :locations do |t|
      t.string :name
      t.string :description
      t.timestamps
    end

    # FIXME "template" is not really the right name.
    create_table :boxhost_provider_templates do |t|
      t.string :provider
      t.string :name
      t.text :config

      t.references :boxhost_plan
      t.references :location
    end
  end
end
