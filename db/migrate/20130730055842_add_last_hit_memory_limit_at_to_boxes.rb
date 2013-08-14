class AddLastHitMemoryLimitAtToBoxes < ActiveRecord::Migration
  def change
    add_column  :boxes, :last_hit_memory_limit_at, :datetime
  end
end
