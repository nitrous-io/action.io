class Api::V0::UsersController < Api::V0::BaseController
  doorkeeper_for :all, scopes: [:user]

  def show
    respond_with current_user
  end
end
