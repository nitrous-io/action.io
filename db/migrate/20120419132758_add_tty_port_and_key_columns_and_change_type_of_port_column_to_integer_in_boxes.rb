class AddTtyPortAndKeyColumnsAndChangeTypeOfPortColumnToIntegerInBoxes < ActiveRecord::Migration
  def up
    add_column    :boxes, :tty_port, :integer
    add_column    :boxes, :key, :string
    rename_column :boxes, :port, :port_string
    add_column    :boxes, :port, :integer
    Box.all.each do |box|
      box.send :generate_key
      box.port = box.port_string.to_i if box.port_string
      box.save validate: false
    end
    change_column :boxes, :key, :string, null: false
    remove_column :boxes, :port_string
  end

  def down
    change_column :boxes, :port, :string
    remove_column :boxes, :key
    remove_column :boxes, :tty_port
  end
end
