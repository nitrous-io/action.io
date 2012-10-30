class AddEnabledAndRuntimeToBoxTemplates < ActiveRecord::Migration
  def change
    add_column :box_templates, :enabled, :boolean, default: false, null: false
    add_column :box_templates, :runtime, :string
  end
end
