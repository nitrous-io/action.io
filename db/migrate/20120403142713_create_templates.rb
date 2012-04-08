class CreateTemplates < ActiveRecord::Migration
  def change
    create_table :templates do |t|
      t.string :name,        null: false
      t.string :image,       null: false
      t.text   :description, null: false
      t.timestamps
    end
  end
end
