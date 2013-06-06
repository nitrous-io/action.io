class AddDemographicInfoToUser < ActiveRecord::Migration
  def change
    add_column :users, :bio, :string
    add_column :users, :location, :string
    add_column :users, :company, :string
    add_column :users, :languages, :text
    add_column :users, :intro_completed, :boolean
  end
end
