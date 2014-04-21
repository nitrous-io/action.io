class AddCollaboratorsMembersAndSnapshotsToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :collaborators, :integer
    add_column :plans, :members, :integer
    add_column :plans, :snapshots, :integer
  end
end
