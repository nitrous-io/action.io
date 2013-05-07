class HomeController < ApplicationController
  layout 'guest'

  def index
    if signed_in?
      redirect_to web_app_url
    elsif(referrer_code = params[:ref]).present?
      if(referrer = Invite.find_by_referral_code(referrer_code)).present?
        Invite.increment_counter(:referred_visits, referrer.id)
      end
    end

    @invite = Invite.new.tap { |i| i.referrer_code = referrer_code }
  end

  def rww
    @invite = Invite.new.tap { |i| i.referrer_code = 'rww' }
    @promo_message = "Hi there, RWW Reader! Be among the first to get access to Nitrous.IO by signing up below."
    render :index
  end

  def tnw
    @invite = Invite.new.tap { |i| i.referrer_code = 'tnw' }
    @promo_message = "Hi there, TNW Reader! Be among the first to get access to Nitrous.IO by signing up below."
    render :index
  end

  def ars
    @invite = Invite.new.tap { |i| i.referrer_code = 'arstechnica' }
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

  def ping
    render text: 'PONG!', layout: false
  end
end

