class AddChromeAppToBonuses < ActiveRecord::Migration
  def change
    add_column :bonuses, :chrome_app, :datetime
  end
end
