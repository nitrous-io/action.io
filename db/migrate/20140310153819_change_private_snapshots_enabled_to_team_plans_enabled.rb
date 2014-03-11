class ChangePrivateSnapshotsEnabledToTeamPlansEnabled < ActiveRecord::Migration
  def change
    rename_column :users, :private_snapshots_enabled, :team_plans_enabled
  end
end
