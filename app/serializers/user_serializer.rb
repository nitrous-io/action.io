class UserSerializer < ActiveModel::Serializer
  attributes :id, :username, :email, :full_name, :available_invites

  has_many :authentications
end
