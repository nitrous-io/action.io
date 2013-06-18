class HomeController < ApplicationController
  layout 'guest'

  def index
    if signed_in?
      redirect_to web_app_url
    end
    @user = User.new
  end

  def rww
    @promo_message = "Hi there, RWW Reader! Be among the first to get access to Nitrous.IO by signing up below."
    render :index
  end

  def tnw
    @promo_message = "Hi there, TNW Reader! Be among the first to get access to Nitrous.IO by signing up below."
    render :index
  end

  def ars
    @promo_message = "Hi there, ArsTechnica Reader! Be among the first to get access to Nitrous.IO by signing up below."
    render :index
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

