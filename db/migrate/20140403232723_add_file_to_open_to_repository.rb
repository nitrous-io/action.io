class AddFileToOpenToRepository < ActiveRecord::Migration
  def change
    add_column  :repositories, :file_to_open, :string
  end
end
