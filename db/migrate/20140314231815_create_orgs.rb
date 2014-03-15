class CreateOrgs < ActiveRecord::Migration
  def change
    create_table :orgs do |t|
      t.string  :name
      t.string  :permalink
      t.string  :billing_email

      t.timestamps
    end

    add_index :orgs, :permalink
  end
end
