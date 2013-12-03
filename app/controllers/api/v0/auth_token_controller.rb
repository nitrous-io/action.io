class Api::V0::AuthTokenController < AuthTokenController
  include CurrentUserFromDoorkeeperToken

  skip_before_filter :authenticate_user!
  doorkeeper_for :all, scopes: [:push]
end
