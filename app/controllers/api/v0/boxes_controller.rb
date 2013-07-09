class Api::V0::BoxesController < BoxesController
  include CurrentUserFromDoorkeeperToken

  skip_before_filter :authenticate_user!
  doorkeeper_for :all, scopes: [:boxes]

  def index
    @boxes = current_user.visible_boxes(owner: current_user)
    respond_with @boxes
  end
end

