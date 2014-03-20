class RepositoriesController < ApplicationController
  before_filter :authenticate_user!

  respond_to :json

  def index
    @repositories = current_user.repositories
    respond_with @repositories
  end

  def identify_scm
    repo = Repository.new(params[:repository])
    repo.state = 'identifying'
    begin
      IdentifyRepositoryJob.submit_job(repo, current_user.id)
      render json: { status: :ok }
    rescue => e
      Rails.logger.error "Error in IdentifyRepositoryJob: #{e}"
      render json: { errors: { repository_clone_url: ["Error cloning #{repo.clone_url}.  If you continue to have problems, please try with this field empty"] } }, status: :unprocessable_entity
    end
  end
end
