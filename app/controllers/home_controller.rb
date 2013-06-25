class HomeController < ApplicationController
  layout 'guest'

  def index
    if signed_in?
      redirect_to web_app_url and return
    end
    @user = User.new
    render layout: 'basic'
  end

  def chat
    redirect_to 'https://www.hipchat.com/gqRzb6GdX'
  end

  def pricing
  end

  def team
  end

  def jobs
  end

  def about
  end

  def join
    signup_params = params[:ref] ? { ref: params[:ref] } : {}
    redirect_to new_user_registration_url signup_params
  end

  def ping
    render text: 'PONG!', layout: false
  end
end

