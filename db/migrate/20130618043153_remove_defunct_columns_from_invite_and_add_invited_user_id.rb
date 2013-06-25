class RemoveDefunctColumnsFromInviteAndAddInvitedUserId < ActiveRecord::Migration
  def up
    remove_column :invites, :invite_code
    remove_column :invites, :ip
    remove_column :invites, :city
    remove_column :invites, :country
    remove_column :invites, :country_code
    remove_column :invites, :latitude
    remove_column :invites, :longitude
    remove_column :invites, :referrer_code
    remove_column :invites, :referred_visits

    add_column  :invites, :invited_user_id, :integer
  end

  def down
    add_column  :invites, :invite_code, :string
    add_column  :invites, :ip, :string
    add_column  :invites, :city, :string
    add_column  :invites, :country_code, :string
    add_column  :invites, :country, :string
    add_column  :invites, :latitude, :string
    add_column  :invites, :longitude, :string
    add_column  :invites, :referrer_code, :string
    add_column  :invites, :referred_visist, :integer, default:0, null: false

    add_index   :invites, :referrer_code
    remove_column :invites, :invited_user_id
  end
end
