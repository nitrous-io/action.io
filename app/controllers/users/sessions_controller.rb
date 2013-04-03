class Users::SessionsController < Devise::SessionsController
  before_filter :handle_redirect_to_param, only: [:create, :create_with_sign_in_token]

  def create_with_sign_in_token
    token = params[:sign_in_token]
    if token && (user = AuthToken.verify(token, 'sign_in'))
      TrackMixpanelEventJob.submit_job('User Signed In', user.id)
      sign_in_and_redirect user
      return
    end
    redirect_to new_user_session_url
  end

  private
  def handle_redirect_to_param
    if params[:redirect_to].present?
      uri = URI.parse root_url
      given = URI.parse params[:redirect_to]
      uri.path = given.path
      uri.fragment = given.fragment
      uri.query = given.query
      session['user_return_to'] = uri.to_s
    end
  end
end

