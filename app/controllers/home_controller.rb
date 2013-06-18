class HomeController < ApplicationController
  layout 'guest'

  def index
    if signed_in?
      redirect_to web_app_url
    end
    @user = User.new
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

  def ping
    render text: 'PONG!', layout: false
  end
end

