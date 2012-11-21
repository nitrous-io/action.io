class ApplicationController < ActionController::Base
  protect_from_forgery
  responders :json

  protected
  def authorize_as_admin!
    unless current_user.present? && current_user.admin?
      render text: "Forbidden", status: 403
    end
  end

  def authorize_as_addon_provider!
    unless current_user.present? && current_user.addon_provider?
      render text: "Forbidden", status: 403
    end
  end
end
