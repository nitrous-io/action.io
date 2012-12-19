class AddIndexToDocuments < ActiveRecord::Migration
  def change
    add_index :documents, [:box_id, :user_id]
  end
end
