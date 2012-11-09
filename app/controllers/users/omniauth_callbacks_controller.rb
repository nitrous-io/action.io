class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    omniauth_hash = request.env['omniauth.auth']
    redirect_to new_user_session_url and return unless omniauth_hash
    render nothing: true, status: 404, layout: false and return unless current_user

    authentication = current_user.authentications.find_by_provider('github')
    unless authentication
      authentication = Authentication.new
      authentication.user = current_user
    end
    authentication.apply_omniauth_hash(omniauth_hash)
    authentication.save!
    flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'GitHub'
    sign_in authentication.user
    redirect_to edit_user_registration_url
  end
end
