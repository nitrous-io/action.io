class BonusSerializer < ActiveModel::Serializer
  attributes :id, :invite_friends, :github, :twitter, :facebook, :linkedin, :accepted_invite, :google
end
