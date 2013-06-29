class UsersController < ApplicationController
  before_filter :authenticate_user!

  respond_to :json

  def intro_seen
    current_user.intro_seen = true
    current_user.save!
    render nothing: true, status: :no_content
  end

  def chrome_app_installed
    current_user.fill_n2o_for_chrome_app_installation!
    render nothing: true, status: :no_content
  end
end
