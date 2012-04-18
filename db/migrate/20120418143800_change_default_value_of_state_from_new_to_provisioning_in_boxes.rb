class ChangeDefaultValueOfStateFromNewToProvisioningInBoxes < ActiveRecord::Migration
  def change
    change_column :boxes, :state, :string, default: 'provisioning', null: false
  end
end
