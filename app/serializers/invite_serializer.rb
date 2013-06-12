class InviteSerializer < ActiveModel::Serializer
  attributes :id, :email, :state, :created_at
end
