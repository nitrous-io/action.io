class RenameValueToJsonValueInKeyValues < ActiveRecord::Migration
  def change
    rename_column :key_values, :value, :json_value
  end
end
