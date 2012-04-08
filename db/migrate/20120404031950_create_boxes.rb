class CreateBoxes < ActiveRecord::Migration
  def change
    create_table :boxes do |t|
      t.string     :name,     null: false
      t.string     :region,   null: false
      t.string     :host
      t.string     :port
      t.string     :status,   null: false, default: 'new'
      t.references :template
      t.timestamps
    end
  end
end
