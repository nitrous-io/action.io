class CreateBoxTransitions < ActiveRecord::Migration
  def change
    create_table :box_transitions do |t|
      t.belongs_to :box
      t.belongs_to :user
      t.string :event, null: false
      t.string :from_state, null: false
      t.string :to_state, null: false
      t.string :triggered_by, default: 'unknown', null: false
      t.datetime :created_at
    end

    add_index :box_transitions, :box_id
    add_index :box_transitions, :triggered_by
    add_index :box_transitions, :user_id
  end
end
