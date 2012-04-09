class RenameTemplatesToBoxTemplates < ActiveRecord::Migration
  def change
    rename_table :templates, :box_templates
    rename_column :boxes, :template_id, :box_template_id
  end
end
