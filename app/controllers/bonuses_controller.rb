class BonusesController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def show
    respond_with current_user.bonus
  end

  def twitter_follow
    current_user.delay.follow_nitrous_on_twitter
    render nothing: true, status: :no_content
  end
end
