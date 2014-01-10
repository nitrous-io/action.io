class AddMemoryAndStorageToPlan < ActiveRecord::Migration
  def change
    add_column 'plans', 'memory', :integer
    add_column 'plans', 'storage', :integer
  end
end
