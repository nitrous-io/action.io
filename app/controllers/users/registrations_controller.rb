class Users::RegistrationsController < Devise::RegistrationsController

  def create
    super
    if resource.persisted?
      UserMailer.delay.welcome resource.email
    end
  end
end

