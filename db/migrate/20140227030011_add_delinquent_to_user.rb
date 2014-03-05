class AddDelinquentToUser < ActiveRecord::Migration
  def change
    add_column :users, :delinquented_at, :datetime
  end
end
