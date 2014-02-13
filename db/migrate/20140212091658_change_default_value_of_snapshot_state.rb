class ChangeDefaultValueOfSnapshotState < ActiveRecord::Migration
  def up
    change_column :snapshots, :state, :string, default: 'queued', null: false
    Snapshot.where(state: 'requested').update_all(state: 'queued')
  end

  def down
    change_column :snapshots, :state, :string, default: 'requested', null: false
    Snapshot.where(state: 'queued').update_all(state: 'requested')
  end
end
