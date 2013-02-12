class Authentication < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :provider, :uid

  def apply_omniauth_hash(hash={})
    self.provider = hash['provider']
    self.uid      = hash['uid']
    if credentials_hash = hash['credentials']
      self.token = credentials_hash['token']
    end
  end
end

# == Schema Information
#
# Table name: authentications
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  provider   :string(255)      not null
#  uid        :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  token      :string(255)
#

