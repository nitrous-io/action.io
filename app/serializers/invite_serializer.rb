class InviteSerializer < ActiveModel::Serializer
  attributes :id, :email, :state, :box_id
end
