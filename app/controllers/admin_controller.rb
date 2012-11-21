class AdminController < ApplicationController
  before_filter :authorize_as_admin!
end
