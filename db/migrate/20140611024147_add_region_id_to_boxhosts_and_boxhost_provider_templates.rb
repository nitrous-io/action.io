class AddRegionIdToBoxhostsAndBoxhostProviderTemplates < ActiveRecord::Migration
  def change
    add_column :boxhosts, :region_id, :integer
    add_column :boxhost_provider_templates, :region_id, :integer

    add_index :boxhosts, :region_id
    add_index :boxhost_provider_templates, :region_id
  end
end
