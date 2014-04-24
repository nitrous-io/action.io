class Users::ConfirmationsController < Devise::ConfirmationsController
  protected
  def after_sign_in_path_for(resource)
    if resource.is_a?(User) && cookies[:coupon_code].present?
      pricing_path
    elsif resource.is_a?(User) && cookies[:hack_repo].present?
      repo = cookies.delete :hack_repo
      runtime = cookies.delete :hack_runtime
      file_to_open = cookies.delete :hack_file_to_open

      hack_button_url(
        repo: repo,
        runtime: runtime,
        file_to_open: file_to_open
      )
    else
      super
    end
  end
end
