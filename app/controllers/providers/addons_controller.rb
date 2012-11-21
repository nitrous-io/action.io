class Providers::AddonsController < ProvidersController
  respond_to :html, only: [:new, :create, :show]

  def new
    @addon = Addon.new
  end

  def create
    @addon = Addon.parse_manifest(params[:addon][:payload])
    @addon.owner = current_user if @addon.present?

    if !@addon.valid?
      render :new
    else
      @addon.save && redirect_to(providers_addon_url(@addon))
    end
  end

  def show
    @addon = current_user.addons.find(params[:id])
  end
end
