class Users::ConfirmationsController < Devise::ConfirmationsController
  protected
  def after_confirmation_path_for(resource_name, resource)
    if resource.is_a?(User) && cookies[:coupon_code].present?
      new_session_path(User, redirect_to: pricing_path)
    elsif resource.is_a?(User) && cookies[:hack].present?
      clone_path = cookies.delete :hack
      new_session_path(User, redirect_to: clone_path)
    else
      super
    end
  end
end
