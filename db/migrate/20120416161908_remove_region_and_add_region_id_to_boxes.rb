class RemoveRegionAndAddRegionIdToBoxes < ActiveRecord::Migration
  def up
    add_column :boxes, :region_id, :integer
    Region.all.each do |region|
      execute "UPDATE boxes SET region_id=#{region.id} WHERE region=#{ActiveRecord::Base.sanitize(region.name)}"
    end
    remove_column :boxes, :region
  end

  def down
    add_column :boxes, :region, :string
    Region.all.each do |region|
      execute "UPDATE boxes SET region=#{ActiveRecord::Base.sanitize(region.name)} WHERE region_id=#{region.id}"
    end
    change_column :boxes, :region, :string, null: false
    remove_column :boxes, :region_id
  end
end
