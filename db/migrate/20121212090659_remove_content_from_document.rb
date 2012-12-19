class RemoveContentFromDocument < ActiveRecord::Migration
  def up
    remove_column :documents, :content
    remove_column :documents, :last_saved_content
  end

  def down
    add_column :documents, :last_saved_content, :text
    add_column :documents, :content, :text
  end
end
