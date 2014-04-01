class Admin::AppUpdatesController < AdminController
  respond_to :html

  def index
    @app_updates = AppUpdate.order('created_at DESC')
    respond_with :admin, @app_updates
  end

  def new
    @app_update = AppUpdate.new
    respond_with :admin, @app_update
  end

  def create
    @app_update = AppUpdate.create params[:app_update]
    respond_with :admin, @app_update
  end

  def show
    find_app_update
    respond_with @app_update
  end

  def edit
    find_app_update
    respond_with @app_update
  end

  def update
    find_app_update
    @app_update.update_attributes params[:app_update]
    respond_with :admin, @app_update
  end

  def destroy
    find_app_update
    @app_update.destroy
    respond_with :admin, @app_update
  end

  private
  def find_app_update
    @app_update = AppUpdate.find params[:id].to_s
  end
end
