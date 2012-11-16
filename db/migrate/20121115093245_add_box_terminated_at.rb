class AddBoxTerminatedAt < ActiveRecord::Migration
  def change
    add_column :boxes, :terminated_at, :datetime
  end
end
