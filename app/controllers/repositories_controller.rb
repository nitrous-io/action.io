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

  def identify_scm
    box = current_user.boxes.find_by_id(params[:repository][:box_id])
    repo_attributes = {clone_url: params[:repository][:clone_url]}
    if params[:repository][:clone_url].blank?
      render json: { errors: { base: ["No url to clone"] } }, status: :unprocessable_entity
      return
    end

    if box.present?
      @repository = box.repositories.create(repo_attributes)
      @repository.initiate_identify!
    else
      @repository = Repository.new(repo_attributes)
      @repository.state = 'identifying'
      IdentifyRepositoryJob.submit_job(@repository, current_user.id)
    end
    @repository.valid?
    render json: @repository.serialize_as_hash
  end
end
