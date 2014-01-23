class AddPlanGroupIdToUser < ActiveRecord::Migration
  def change
    add_column  :users, :plan_group_id, :integer
  end
end
