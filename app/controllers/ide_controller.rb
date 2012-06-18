class IdeController < ApplicationController
  before_filter :authenticate_user!
  layout 'basic'

  def index
    @boxes = current_user.boxes
    @regions = Region.where(enabled: true).order(:id)
  end
end
