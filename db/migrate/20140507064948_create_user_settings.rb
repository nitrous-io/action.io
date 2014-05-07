class CreateUserSettings < ActiveRecord::Migration
  def change
    create_table :user_settings do |t|
      t.references :user, null: false
      t.boolean :auto_close_brackets, default: true
      t.boolean :highlight_line, default: true
      t.string :keybindings, default: 'default'
      t.boolean :match_brackets, default: true
      t.integer :ruler_column, default: nil
      t.boolean :show_line_numbers, default: true
      t.boolean :show_trailing_space, default: false
      t.boolean :soft_tabs, default: true
      t.integer :tab_size, default: 2
      t.string :theme, default: 'vibrant-ink'
      t.boolean :wrap_lines, default: true
      t.timestamps
    end

    add_index :user_settings, :user_id
  end
end
