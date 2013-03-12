class AddStateToRegion < ActiveRecord::Migration
  def change
    add_column :regions, :state, :string, default: :up, null: false
  end
end
