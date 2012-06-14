class ApplicationController < ActionController::Base
  protect_from_forgery
  responders :json

  protected
  def authorize_user!
    unless current_user.present? && current_user.admin?
      render :text => "Forbidden", :status => 403
    end
  end
end
