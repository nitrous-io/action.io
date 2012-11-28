class Api::V0::BoxesController < BoxesController
  skip_before_filter :authenticate_user!
  doorkeeper_for :all, scopes: [:boxes]

  def current_user
    User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end
end

