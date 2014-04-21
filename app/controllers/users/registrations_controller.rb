class Users::RegistrationsController < Devise::RegistrationsController
  before_filter :set_mixpanel_cookie_information, only: [:create]
  before_filter :configure_permitted_parameters, only: [:create]

  respond_to :json, only: :update

  def new
    if params[:intent]
      user = User.new(intent: params[:intent])
      if user.intent[:kind] == 'clone_repo'
        @clone_repo = true
      end
    end

    super
  end

  def create
    build_resource(sign_up_params)

    if resource.save
      @mixpanel_attributes[:coupon_code] = resource.coupon_code if resource.coupon_code.present?
      @mixpanel_attributes[:intent] = resource.intent[:kind] if resource.intent.present?

      IdentifyMixpanelUserJob.submit_job(resource.id, @mixpanel_attributes)
      TrackMixpanelEventJob.submit_job('User Signed Up', resource.id, @mixpanel_attributes)

      # Delete distinct_id since that might change,
      # when the user first visits the nitrous.io website, his distinct_id is
      # auto generated, but is then changed when his id is alias'ed
      user_profile = resource.user_profile
      mixpanel_properties = @mixpanel_attributes.dup
      mixpanel_properties.delete('distinct_id')

      user_profile.mixpanel_properties = mixpanel_properties
      user_profile.save

      # Devise code.
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_up(resource_name, resource)
        respond_with resource, :location => after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      if resource.intent.present?
        if resource.intent[:kind] == 'clone_repo'
          @clone_repo = true
        end
        @intent = resource.intent.to_query
      end

      # Devise code.
      clean_up_passwords resource
      respond_with resource
    end

    if params[:ref].present?
      n2o = KeyValue[N2oFill::N2O_INVITED_SIGNUP_BONUS]
      flash[:info] = "Sign up with this referral code and earn #{n2o} extra units of N2O."
    end
  end

  def edit
    redirect_to web_app_url(anchor: '/account')
  end

  def update
    @user = User.find(current_user.id)
    params[:user].delete(:current_password)
    params[:user].delete(:username)
    @user.update_without_password(params[:user])

    respond_with @user
  end

  protected
  # See https://github.com/plataformatec/devise#strong-parameters.
  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) do |u|
      u.permit(
        :username,
        :email,
        :referrer_code,
        :password,
        :password_confirmation,
        :coupon_code,
        :intent,
      )
    end
  end

  def set_mixpanel_cookie_information
    if (mp_cookies = cookies['mp_aio'])
      @mixpanel_attributes = JSON.parse(mp_cookies)
    else
      @mixpanel_attributes = {}
    end
  end

  def after_update_path_for(resource)
    edit_user_registration_path
  end

  def after_inactive_sign_up_path_for(resource)
    root_url(confirm_email: resource.email)
  end
end
