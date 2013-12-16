class Admin::CouponsController < AdminController
  layout 'dashboard'
  respond_to :html

  def index
    @coupons = Coupon.order('created_at DESC')
    respond_with :admin, @coupon
  end

  def new
    @coupon = Coupon.new
    respond_with :admin, @coupon
  end

  def create
    @coupon = Coupon.generate(params[:coupon])

    if @coupon.persisted?
      redirect_to admin_coupons_path
    else
      render :new
    end
  end

  def deactivate
    @coupon = Coupon.find params[:id]
    @coupon.update_attribute 'active', false

    flash[:notice] = "Deactivated the coupon \"#{@coupon.code}\""
    redirect_to admin_coupons_path
  end

  def activate
    @coupon = Coupon.find params[:id]
    @coupon.update_attribute 'active', true

    flash[:notice] = "Activated the coupon \"#{@coupon.code}\""
    redirect_to admin_coupons_path
  end
end
