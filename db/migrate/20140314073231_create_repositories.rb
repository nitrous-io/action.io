class CreateRepositories < ActiveRecord::Migration
  def change
    create_table :repositories do |t|
      t.belongs_to :box
      t.string :name
      t.string :full_name
      t.string :clone_url
      t.string :state, default: :queued, null: false
      t.integer :scm, default: 0 # Enum.
      t.boolean :private, default: false
      t.datetime :cloned_at
      t.timestamps
    end

    add_index :repositories, :box_id
  end
end
