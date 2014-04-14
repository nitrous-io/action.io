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

    current_user.delay.send_tweet(message) unless message.blank?
    render nothing: true, status: :no_content
  end

  def disconnect
    service = params[:service]
    bonusList = current_user.bonus

    unless bonusList[service]
      render(json: { errors: { base: [ "Service not connected." ] } }, status: :unprocessable_entity) and return
    end

    if current_user.free_n2o > 0
      n2o_fill_kind = "N2oFill::Kind::OAUTH_#{service.upcase}_CONNECT".constantize

      ActiveRecord::Base.transaction do
        bonusList.update_column service, nil
        current_user.n2o_fills.where(kind: n2o_fill_kind).destroy_all
        current_user.authentications.where(provider: service).destroy_all
      end

      render nothing: true, status: :no_content
    else
      render json: { errors: { base: [ "You are currently using all available N2O. You will need to free up some N2O to disconnect the service." ] } }, status: :unprocessable_entity
    end
  end
end
