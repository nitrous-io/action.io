class RemoveRegionIdFromBoxes < ActiveRecord::Migration
  def up
    # There exist {failed,terminated} boxes on production where host IS NULL
    # For these we randomly pick a boxhost with the same region_id so the
    # validation is met and region_id is preserved.
    execute <<-SQL
      UPDATE boxes SET boxhost_id = boxhosts.id
        FROM boxhosts WHERE boxhosts.name = boxes.host AND boxes.host IS NOT NULL
    SQL

    execute <<-SQL
      UPDATE boxes SET boxhost_id = boxhosts.id
        FROM boxhosts WHERE boxhosts.region_id = boxes.region_id AND boxes.host IS NULL
    SQL

    remove_column :boxes, :region_id
  end

  def down
    add_column :boxes, :region_id, :integer

    execute <<-SQL
      UPDATE boxes SET region_id = boxhosts.region_id
        FROM boxhosts WHERE boxhosts.id = boxes.boxhost_id
    SQL
  end
end
