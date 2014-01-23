class CreatePlanGroupMemberships < ActiveRecord::Migration
  def change
    create_table :plan_group_memberships do |t|
      t.integer :plan_group_id, null: false
      t.integer :plan_id,       null: false

      t.timestamps
    end

    add_index :plan_group_memberships, :plan_id
    add_index :plan_group_memberships, :plan_group_id
  end
end
