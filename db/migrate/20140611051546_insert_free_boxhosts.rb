class InsertFreeBoxhosts < ActiveRecord::Migration
  def up
    execute <<-SQL
      INSERT INTO boxhosts
        (name, region_id, type)
      SELECT DISTINCT(host), region_id, 'FreeBoxhost' FROM boxes WHERE host IS NOT NULL
    SQL
  end

  def down
    puts "no-op (remove the boxhosts manually)"
  end
end
