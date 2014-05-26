class BoxhostsController < ApplicationController
  protect_from_forgery

  before_filter :authenticate_user!
  before_filter :check_if_delinquent_user!
  before_filter :allow_only_dedicated_users

  respond_to :json

  def index
    @boxhosts = current_user.visible_boxhosts
    respond_with @boxhosts
  end
end
