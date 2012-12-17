class Api::V0::PublicKeysController < PublicKeysController
  include CurrentUserFromDoorkeeperToken

  skip_before_filter :authenticate_user!
  doorkeeper_for :all, scopes: [:public_keys]
end
