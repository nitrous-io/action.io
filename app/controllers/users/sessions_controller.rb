class Users::SessionsController < Devise::SessionsController
  before_filter :handle_redirect_to_param, only: [:create, :create_with_sign_in_token]

  def create_with_sign_in_token
    token = params[:sign_in_token]
    if token.present? && (token = message_verifier.verify token)
      user_id = token[0]
      expiry_time = token[1]
      if Time.now < Time.at(expiry_time)
        user = User.find user_id
        sign_in_and_redirect user
        return
      end
    end
    redirect_to new_user_session_url
  end

  private
  def handle_redirect_to_param
    session['user_return_to'] = params[:redirect_to] if params[:redirect_to].present?
  end
end

