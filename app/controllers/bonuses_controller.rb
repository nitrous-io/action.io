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

  def send_tweet
    message = params[:message] || ''
    referral_link = join_shortcut_url(ref: current_user.referral_code)
    full_message = "I love @NitrousIO because #{message[0..60]} - #{referral_link}"

    current_user.delay.send_tweet full_message
    render nothing: true, status: :no_content
  end
end
