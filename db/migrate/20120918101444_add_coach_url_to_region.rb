class AddCoachUrlToRegion < ActiveRecord::Migration
  def change
    add_column :regions, :coach_uri, :string
  end
end
