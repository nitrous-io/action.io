class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.string      :name, null: false
      t.references  :org

      t.timestamps
    end
  end
end
