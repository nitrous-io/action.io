class ChangeDefaultValueOfBoxStateToBorn < ActiveRecord::Migration
  def up
    change_column :boxes, :state, :string, default: 'born', null: false
  end

  def down
    change_column :boxes, :state, :string, default: 'provisioning', null: false
  end
end
