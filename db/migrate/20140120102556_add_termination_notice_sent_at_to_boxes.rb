class AddTerminationNoticeSentAtToBoxes < ActiveRecord::Migration
  def change
    add_column :boxes, :termination_notice_sent_at, :datetime
  end
end
