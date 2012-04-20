class ChangeDefaultValueOfStateFromNewToProvisioningInBoxes < ActiveRecord::Migration
  def up
    change_column :boxes, :state, :string, default: 'provisioning', null: false
  end

  def down
    change_column :boxes, :state, :string, default: 'new', null: false
  end
end
