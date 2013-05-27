class AddDemoColumnToPlan < ActiveRecord::Migration
  def change
    add_column :plans, :demo, :boolean
  end
end
