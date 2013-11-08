class AdminController < ApplicationController
  before_filter :authorize_user!
  http_basic_authenticate_with name: Settings.admin_username, password: Settings.admin_password
end
