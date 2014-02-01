class HomeController < ApplicationController
  layout 'guest'

  before_action :set_coupon, only: [:index]

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
    if signed_in?
      redirect_to "#{web_app_url}/#/n2o/upgrade" and return
    end

    @plans = Plan.global
  end

  def team
  end

  def jobs
  end

  def about
  end

  def business
    render :business, layout: 'survey'
  end

  def user_survey_1
    render :user_survey_1, layout: 'survey'
  end

  def collab
    render :collab, layout: 'basic'
  end

  def ping
    render text: 'PONG!', layout: false
  end

  private
  def set_coupon
    return if params[:coupon_code].blank?

    @coupon = Coupon.find_by_code(params[:coupon_code].downcase)
    if @coupon.nil?
      flash.now[:info] = "Sorry that's not a valid coupon code."
      return
    end
    if !@coupon.active
      flash.now[:info] = "Sorry that coupon is no longer valid."
      return
    end

    cookies[:coupon_code] = @coupon.code

    if signed_in?
      if current_user.eligible_for_coupon?
        current_user.coupon_code = @coupon.code
        current_user.save
      end

      redirect_to pricing_path
    else
      flash.now[:info] = "Please sign in or sign up to take advantage of this coupon code (#{@coupon.description})."
    end
  end
end

