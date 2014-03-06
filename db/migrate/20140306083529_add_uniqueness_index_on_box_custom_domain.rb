class AddUniquenessIndexOnBoxCustomDomain < ActiveRecord::Migration
  def up
    add_index :boxes, :custom_domain, unique: true
  end

  def down
    remove_index :boxes, :custom_domain
  end
end
