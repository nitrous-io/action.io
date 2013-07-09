class Api::V0::BoxesController < BoxesController
  include CurrentUserFromDoorkeeperToken

  skip_before_filter :authenticate_user!
  doorkeeper_for :all, scopes: [:boxes]

  def index
    @boxes = current_user.owned_boxes.order("id ASC")
    respond_with @boxes
  end
end

