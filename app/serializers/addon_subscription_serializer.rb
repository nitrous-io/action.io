class AddonSubscriptionSerializer < ActiveModel::Serializer
  attributes :id, :addon_plan_id, :box_id, :state, :env_vars

  def env_vars
    env_vars = object.env_vars.present? ? object.env_vars : "{}"
    JSON.parse env_vars
  end
end
