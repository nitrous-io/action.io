class Api::V0::UsersController < Api::V0::BaseController
  doorkeeper_for :all, scopes: [:user], except: [:sign_in_token]
  doorkeeper_for :sign_in_token, scopes: [:web]

  def show
    respond_with current_user
  end

  def sign_in_token
    respond_with sign_in_token: SignInToken.generate(current_user)
  end
end
