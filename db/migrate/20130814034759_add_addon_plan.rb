class AddAddonPlan < ActiveRecord::Migration
  def change
    create_table :addon_plans do |t|
      t.references :addon
      t.string :name, null: false
      t.integer :price
      t.timestamps
    end

    create_table :addon_plan_benefits do |t|
      t.references :addon_plan
      t.string :name, null: false
      t.string :value, null: false
      t.timestamps
    end
  end
end
