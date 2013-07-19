class HomeController < ApplicationController
  layout 'guest'

  def index
    if signed_in?
      redirect_to web_app_url and return
    end
    if (referral_code = params[:ref]).present?
      inviting_user = User.find_by_referral_code(referral_code)

      n2o = inviting_user.try(:referral_n2o) || KeyValue[N2oFill::N2O_INVITED_SIGNUP_BONUS]
      flash.now[:info] = "Sign up with this referral code and earn #{n2o} extra units of N2O."
    end
    @user = User.new

    if (email = params[:email]).present?
      @user.email = email
    end

    render layout: 'basic'
  end

  def chat
    redirect_to 'https://www.hipchat.com/gkbrGh4Bi'
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

  def business
    render :business, layout: 'business'
  end

  def collab
    render :collab, layout: 'basic'
  end

  def ping
    render text: 'PONG!', layout: false
  end
end

