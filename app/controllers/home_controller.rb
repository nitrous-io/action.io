class HomeController < ApplicationController
  layout 'guest'

  def index
    redirect_to console_url if signed_in?
  end
end

