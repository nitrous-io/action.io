class RepositoriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :check_if_delinquent_user!

  respond_to :json

  def index
    @repositories = current_user.repositories
    respond_with @repositories
  end

  def show
    @repository = current_user.repositories.detect {|repo| repo.id.to_s == params[:id] }
    raise ActiveRecord::RecordNotFound if @repository.nil?
    respond_with @repository
  end
end
