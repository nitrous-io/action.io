module CurrentUserFromDoorkeeperToken
  def current_user
    if doorkeeper_token
      @current_user ||= User.find(doorkeeper_token.resource_owner_id)
    else
      error = Doorkeeper::OAuth::ErrorResponse.new(name: :invalid_request)
      render json: error.body, status: error.status and return
    end
  end
end
