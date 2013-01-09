class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    omniauth_hash = request.env['omniauth.auth']
    redirect_to new_user_session_url and return unless omniauth_hash
    render nothing: true, status: 404, layout: false and return unless current_user

    authentication = current_user.authentications.find_by_provider('github')
    authentication_existed = authentication.present?
    unless authentication_existed
      authentication = Authentication.new
      authentication.user = current_user
    end
    authentication.apply_omniauth_hash(omniauth_hash)

    if authentication.save!
      unless authentication_existed
        METRICS.increment "users.github.connected"
      end
    end

    flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'GitHub'
    sign_in authentication.user
    redirect_to edit_user_registration_url
  end
end
