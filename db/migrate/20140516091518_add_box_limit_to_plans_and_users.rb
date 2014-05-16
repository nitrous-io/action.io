class AddBoxLimitToPlansAndUsers < ActiveRecord::Migration
  def change
    add_column :plans, :box_limit, :integer

    add_column :users, :box_limit, :integer, default: 1
  end
end
