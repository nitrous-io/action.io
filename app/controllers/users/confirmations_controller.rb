class Users::ConfirmationsController < Devise::ConfirmationsController
  protected
  def after_sign_in_path_for(resource)
    if resource.is_a?(User) && cookies[:coupon_code].present?
      pricing_path
    elsif resource.is_a?(User) && 'clone_repo' == resource.intent[:kind]
      clone_repository_path(url: resource.intent[:data][:url])
    else
      super
    end
  end
end
