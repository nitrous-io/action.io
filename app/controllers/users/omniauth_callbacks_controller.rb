class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  before_filter :allow_only_signed_in!, only: [:twitter, :facebook]
  after_filter  :update_mixpanel, :fill_n2o, :post_oauth_authenticate_hook

  def github
    authenticate_callback 'Github'
  end

  def google_oauth2
    authenticate_callback 'Google'
  end

  def linkedin
    authenticate_callback 'LinkedIn'
  end

  def twitter
    authenticate_callback 'Twitter'
  end

  def facebook
    authenticate_callback 'Facebook'
  end

  protected
  def authenticate_callback(provider)
    @provider = provider.downcase
    will_sign_in = true
    redirect_to new_user_session_url and return unless omniauth_hash

    if (user = authenticating_user)
      user.update_omniauth_authentication omniauth_hash
      authentication = current_authentication

      authentication.update_attribute(:confirmed, true) if current_user.present?

      if authentication.confirmed?
        flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: provider
        redirect_path = current_user.present? ? BONUS_PATH : root_path
      else
        will_sign_in = false
        token = omniauth_hash['credentials']['token']
        redirect_path = edit_authentication_path(authentication, token: token )
      end
    else
      user = User.create_from_omniauth_data omniauth_hash
      if user.persisted?
        user.confirm!
        flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: provider
      else
        flash[:notice] = "Cannot create new user. Please try again"
      end

      redirect_path = root_path
    end

    sign_in user if user.persisted? && will_sign_in

    redirect_to redirect_path
  end

  def update_mixpanel
    if current_user.present?
      mixpanel_property = :"is_#{@provider}_authenticated"
      SetMixpanelPropertyJob.submit_job(current_user.id, mixpanel_property, true)
    end
  end

  def fill_n2o
    if current_user.present?
      current_user.fill_n2o_for_oauth_action! @provider
    end
  end

  def post_oauth_authenticate_hook
    return unless authenticating_user
    case @provider
    when 'twitter' then TrackTwitterInfoOnMixpanelJob.submit_job authenticating_user.id
    when 'github'  then TrackGithubInfoOnMixpanelJob.submit_job authenticating_user.id
    when 'linkedin' then TrackLinkedinInfoOnMixpanelJob.submit_job authenticating_user.id
    end
  end

  # perform several strategies to find an user who's authenticating
  # - get current_user if possible
  # - get an user who email matched the auth data ( this may be an user who
  # register with the same email, or user who register with oauth data (hence
  # has the email filled with oauth data )
  # - get the user whose authentications contains the same provider and uid
  def authenticating_user
    @authenticating_user ||= current_user ||
      User.find_by_email(omniauth_hash['info']['email'])
    unless @authenticating_user
      @authenticating_user = current_authentication.user if current_authentication
    end
    @authenticating_user
  end

  # find the current authentication if possible via provided provider and
  # uid of omniauth_hash
  #
  # Returns an instance of `Authentication` or nil when the user doesnt have any
  # existing authentication
  def current_authentication
    @current_authentication ||= Authentication.
      where(provider: omniauth_hash['provider'], uid: omniauth_hash['uid']).
      first
  end

  def omniauth_hash
    @omniauth_hash ||= request.env['omniauth.auth']
    # reset omniauth_hash provider to a reasonable value that we use throughout
    # the app
    if @omniauth_hash['provider'] == 'google_oauth2'
      @omniauth_hash['provider'] = 'google'
    end
    @omniauth_hash
  end

  def allow_only_signed_in!
    redirect_to new_user_session_url unless current_user.present?
  end
end
