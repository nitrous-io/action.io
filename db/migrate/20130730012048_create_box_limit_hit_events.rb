class CreateBoxLimitHitEvents < ActiveRecord::Migration
  def change
    create_table :box_limit_hit_events do |t|
      t.string    :kind
      t.string    :logged_event_id
      t.datetime  :limit_hit_at
      t.integer   :box_id

      t.timestamps
    end

    add_index :box_limit_hit_events, :box_id
    add_index :box_limit_hit_events, :logged_event_id
  end
end
