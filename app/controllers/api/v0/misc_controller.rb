class Api::V0::MiscController < Api::V0::BaseController
  doorkeeper_for :all

  def scopes
    render json: { scopes: doorkeeper_token.scopes.to_s }
  end
end
