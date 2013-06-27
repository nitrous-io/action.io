class ChangeAvailableInvitesToRewardableInvitesCountOnUser < ActiveRecord::Migration
  def up
    rename_column :users, :available_invites, :rewardable_invites_count
  end

  def down
    rename_column :users, :rewardable_invites_count, :available_invites
  end
end
