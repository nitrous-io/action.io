class AddTwitterFollowToBonuses < ActiveRecord::Migration
  def change
    add_column :bonuses, :twitter_follow, :datetime
  end
end
