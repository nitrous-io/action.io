class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    omniauth_hash = request.env['omniauth.auth']
    redirect_to new_user_session_url and return unless omniauth_hash

    if current_user
      authentication = current_user.authentications.find_by_provider('github')
      unless authentication
        authentication = Authentication.new
        authentication.user = current_user
      end
      authentication.apply_omniauth_hash(omniauth_hash)
      authentication.save!
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'GitHub'

      sign_in authentication.user

      # Set Mixpanel Property
      SetMixpanelPropertyJob.submit_job(authentication.user.id, :is_github_authenticated, true)

      redirect_to edit_user_registration_url
    else
      user = User.find_by_email(omniauth_hash['info']['email'])
      if user.present?
        authentication = user.authentications.find_by_provider('github')
        unless authentication
          authentication = Authentication.new
          authentication.user = user
        end
        authentication.apply_omniauth_hash(omniauth_hash)
        authentication.save!
        sign_in user
        redirect_to root_path
      else
        user = User.new.tap do |u|
          u.email = omniauth_hash['info']['email']
          u.password = SecureRandom.hex(7)
          u.full_name = omniauth_hash['info']['name']
        end
        authentication = Authentication.new
        authentication.apply_omniauth_hash(omniauth_hash)
        user.authentications << authentication
        if user.save
          sign_in user
          redirect_to root_path
        else
          flash['notice'] = "Cannot create new user. Please try again"
          redirect_to root_path
        end
      end
    end
  end
end
