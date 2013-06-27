class BonusesController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def show
    respond_with current_user.bonus
  end
end
