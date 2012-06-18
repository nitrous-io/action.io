class HomeController < ApplicationController
  layout 'guest'

  def index
    redirect_to ide_url if signed_in?
  end

  def pricing
  end

  def ping
    render text: 'PONG!', layout: false
  end
end

