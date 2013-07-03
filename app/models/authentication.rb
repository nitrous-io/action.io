class Authentication < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :provider, :uid

  def apply_omniauth_hash(hash={})
    self.provider = hash['provider']
    self.uid      = hash['uid']
    self.meta     = hash.to_json
    if credentials_hash = hash['credentials']
      self.token = credentials_hash['token']
      self.secret = credentials_hash['secret'] if credentials_hash['secret']
    end
    username = hash.fetch("info", {}).fetch("nickname", {})
    if username.present?
      self.username = username
    end
  end
end
