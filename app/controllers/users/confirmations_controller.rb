class Users::ConfirmationsController < Devise::ConfirmationsController
  protected
  def after_sign_in_path_for(resource)
    if resource.is_a?(User) && cookies[:coupon_code].present?
      pricing_path
    elsif resource.is_a?(User) && 'clone_repo' == resource.intent[:kind]
      hack_button_url(
        repo: resource.intent[:data][:repo],
        url: resource.intent[:data][:url],
        runtime: resource.intent[:data][:runtime],
        file_to_open: resource.intent[:data][:file_to_open]
      )
    else
      super
    end
  end
end
