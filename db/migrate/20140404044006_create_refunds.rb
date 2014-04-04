class CreateRefunds < ActiveRecord::Migration
  def change
    create_table :refunds do |t|
      t.belongs_to :user
      t.integer :amount_in_cents
      t.string  :stripe_charge_id
      t.string  :reason
      t.timestamp :processed_at

      t.timestamps
    end
  end
end
