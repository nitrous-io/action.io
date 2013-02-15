class UserSerializer < ActiveModel::Serializer
  attributes :id, :username, :email, :full_name, :available_invites, :created_at, :admin

  has_many :authentications
end
