class RepositoriesController < ApplicationController
  before_filter :authenticate_user!

  respond_to :json

  def index
    @repositories = current_user.repositories
    respond_with @repositories
  end
end
