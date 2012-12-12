class AddLastSavedContentToDocument < ActiveRecord::Migration
  def up
    remove_column :documents, :clean
    add_column :documents, :last_saved_content, :text
  end

  def down
    remove_column :documents, :last_saved_content
    add_column :documents, :clean, :boolean
  end
end
