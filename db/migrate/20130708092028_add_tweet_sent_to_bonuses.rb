class AddTweetSentToBonuses < ActiveRecord::Migration
  def change
    add_column :bonuses, :tweet_sent, :datetime
  end
end
