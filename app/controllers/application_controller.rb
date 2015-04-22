class ApplicationController < ActionController::Base
  before_filter :check_user_login_status
  protect_from_forgery
  ensure_security_headers
  responders :json

  BONUS_PATH = "/app#/n2o/bonus".freeze

  def check_user_login_status
    if current_user && !current_user.able_to_login?
      redirect_to new_confirmation_path
    end
  end

  # This method MUST be present, otherwise protect_from_forgery will just give
  # a warning and continue with the controller action.
  # Since single-page Ember app doesn't change tokens, we ignore CSRF token for
  # json requests (specified with jQuery by X-Requested-With header, which is
  # what xhr? checks for).
  def handle_unverified_request
    super

    # allow oauth (desktop app)
    return true if (request.headers['Authorization'] || '').starts_with?('Bearer')
    # allow json requests
    return true if request.xhr?

    sign_out
    render :text => "Forbidden", :status => 403
  end

  protected
  def authorize_user!
    unless current_user.present? && current_user.admin?
      render :text => "Forbidden", :status => 403
    end
  end

  def check_if_delinquent_user!
    if current_user.delinquent?
      render json: { errors: { base: ['Your account has an overdue payment. You will need to settle the payment to access your boxes again.'] } }, status: 403
    end
  end

  def allow_only_dedicated_users
    unless current_user.dedicated_allowed
      render nothing: true, status: :forbidden
    end
  end

  def split_alternatives
    alternatives = []

    yaml = YAML.load(File.read(Settings.split_alternatives_config))

    if (controller = yaml[controller_name.to_s])
      if(action = controller[action_name.to_s])
        alternatives = action[Rails.env.to_s] || []
      end
    end

    alternatives
  end

  def oauth_token_present?
    Doorkeeper::OAuth::Token.from_request(request, *Doorkeeper.configuration.access_token_methods).present?
  end

  def no_cache
    expires_now
  end

  def after_sign_in_path_for(resource)
    web_app_path
  end

  def after_sign_out_path_for(resource_or_scope)
    "https://lite.nitrous.io/"
  end
end
