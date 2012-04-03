class Users::RegistrationsController < Devise::RegistrationsController
  before_filter :clear_omniauth, :only => [:new, :create]

  def clear_omniauth
    if params[:omniauth].to_s != '1'
      session.delete 'devise.omniauth_hash'
    end
  end
end

