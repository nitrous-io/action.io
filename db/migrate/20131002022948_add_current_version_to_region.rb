class AddCurrentVersionToRegion < ActiveRecord::Migration
  def change
    add_column :regions, :version, :string
  end
end
