class InviteSerializer < ActiveModel::Serializer
  attributes :id, :email, :state, :created_at, :n2o_earned
end
