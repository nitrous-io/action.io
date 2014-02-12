class AddCustomDomainToBox < ActiveRecord::Migration
  def change
    add_column :boxes, :custom_domain, :string
  end
end
