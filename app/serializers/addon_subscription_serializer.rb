class AddonSubscriptionSerializer < ActiveModel::Serializer
  attributes :id, :addon_plan_id, :box_id, :state, :env_vars

  def env_vars
    JSON.parse object.env_vars
  end
end
