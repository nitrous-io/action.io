class Admin::MacAppUpdatesController < AdminController
  layout 'dashboard'
  respond_to :html

  def index
    @mac_app_updates = MacAppUpdate.order('created_at DESC')
    respond_with :admin, @mac_app_updates
  end

  def new
    @mac_app_update = MacAppUpdate.new
    respond_with :admin, @mac_app_update
  end

  def create
    @mac_app_update = MacAppUpdate.create params[:mac_app_update]
    respond_with :admin, @mac_app_update
  end

  def show
    find_mac_app_update
    respond_with @mac_app_update
  end

  def edit
    find_mac_app_update
    respond_with @mac_app_update
  end

  def update
    find_mac_app_update
    @mac_app_update.update_attributes params[:mac_app_update]
    respond_with :admin, @mac_app_update
  end

  def destroy
    find_mac_app_update
    @mac_app_update.destroy
    respond_with :admin, @mac_app_update
  end

  private
  def find_mac_app_update
    @mac_app_update = MacAppUpdate.find params[:id].to_s
  end
end
