class AdminController < ApplicationController
  before_filter :authorize_user!
end
