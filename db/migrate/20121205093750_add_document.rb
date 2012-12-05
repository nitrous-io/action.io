class AddDocument < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.references :user, null: false
      t.references :box, null: false
      t.boolean :dirty, default: false
      t.string :path, null: false
      t.text :content
      t.timestamps
    end
  end
end
