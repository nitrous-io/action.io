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
    @n2o_128mb_memory  = KeyValue[N2oAllocation::N2O_128MB_MEMORY]
    @n2o_250mb_storage = KeyValue[N2oAllocation::N2O_250MB_STORAGE]
    @n2o_price_cents   = KeyValue[AIO::N2O_PRICE_CENTS]
    @free_n2o          = KeyValue[N2oFill::N2O_SIGN_UP_BONUS]
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

