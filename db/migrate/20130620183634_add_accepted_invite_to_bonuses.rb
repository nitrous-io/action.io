class AddAcceptedInviteToBonuses < ActiveRecord::Migration
  def change
    add_column :bonuses, :accepted_invite, :datetime
  end
end
