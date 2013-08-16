class Api::V0::BoxesController < BoxesController
  include CurrentUserFromDoorkeeperToken

  skip_before_filter :authenticate_user!
  doorkeeper_for :all, scopes: [:boxes]

end

