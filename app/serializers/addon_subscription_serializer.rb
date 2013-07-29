class AddonSubscriptionSerializer < ActiveModel::Serializer
  attributes :id, :addon_id, :box_id, :state
end
