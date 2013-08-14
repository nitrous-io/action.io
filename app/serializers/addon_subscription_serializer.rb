class AddonSubscriptionSerializer < ActiveModel::Serializer
  attributes :id, :addon_plan_id, :box_id, :state
end
