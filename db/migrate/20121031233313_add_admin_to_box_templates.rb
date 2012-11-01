class AddAdminToBoxTemplates < ActiveRecord::Migration
  def change
    add_column  :box_templates, :admin, :boolean, default: false, null: false
  end
end
