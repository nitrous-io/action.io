class RemoveCardFieldsFromSubscriptions < ActiveRecord::Migration
  def up
    remove_column :subscriptions, :last_four
    remove_column :subscriptions, :card_type
  end

  def down
    add_column :subscriptions, :last_four, :string
    add_column :subscriptions, :card_type, :string
  end
end
