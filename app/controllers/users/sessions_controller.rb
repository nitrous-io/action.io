class Users::SessionsController < Devise::SessionsController
  doorkeeper_for :create, if: -> { request.headers['Authorization'].present? }, scopes: [:web]

  def create
    session['user_return_to'] = params[:redirect_to] if params[:redirect_to].present?
    if doorkeeper_token
      user = User.find doorkeeper_token.resource_owner_id
      sign_in_and_redirect user
    else
      super
    end
  end
end

