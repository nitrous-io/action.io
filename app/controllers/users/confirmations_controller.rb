class Users::ConfirmationsController < Devise::ConfirmationsController
  protected
  def after_sign_in_path_for(resource)
    if resource.is_a?(User) && cookies[:coupon_code].present?
      pricing_path
    else
      super
    end
  end
end
