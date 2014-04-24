class AddDownloadBranchToRepositories < ActiveRecord::Migration
  def change
    add_column :repositories, :download_branch, :string, default: 'master'
  end
end
