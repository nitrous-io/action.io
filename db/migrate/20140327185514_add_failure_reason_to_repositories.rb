class AddFailureReasonToRepositories < ActiveRecord::Migration
  def change
    add_column :repositories, :failure_reason, :text
  end
end
