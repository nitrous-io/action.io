class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def passthru
    render nothing: true, status: 404, layout: false
  end

  def github
    omniauth_hash = request.env['omniauth.auth']
    redirect_to new_user_session_url and return unless omniauth_hash

    authentication = Authentication.find_by_provider_and_uid('github', omniauth_hash['uid'].to_s)
    unless authentication
      user = User.new
      user.apply_omniauth_hash(omniauth_hash)
      user.save
      unless user.persisted?
        session['devise.omniauth_hash'] = omniauth_hash.except('extra')
        redirect_to new_user_registration_url omniauth: '1', required_fields: user.errors.keys.join(' ') and return
      end
    else
      authentication.apply_omniauth_hash(omniauth_hash)
      authentication.save!
    end
    flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'GitHub'
    sign_in_and_redirect user || authentication.user, event: :authentication
  end
end

