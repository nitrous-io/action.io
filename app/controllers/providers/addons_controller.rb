class Providers::AddonsController < ProvidersController
  respond_to :html, only: [:show]
  respond_to :json, only: [:create]
  doorkeeper_for :create, :scopes => [:addons]
  before_filter :authorize_as_addon_provider!, except: [:create]

  def create
    @addon = Addon.parse_manifest(params[:addon][:payload])
    @addon.owner = current_resource_owner if @addon.present?

    if @addon.valid?
      @addon.save
      render :nothing => true
    else
      err_msg = 'Invalid manifest: ' << @addon.errors.map { |k,v| "#{k} #{v}" }.join('. ')
      render :text => err_msg, :status => 403
    end
  end

  def show
    @addon = current_user.addons.find(params[:id])
  end
end
