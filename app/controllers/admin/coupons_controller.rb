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
    @coupon = Coupon.create params[:coupon]
    respond_with :admin, @coupon
  end

  def show
    find_coupon
    respond_with @coupon
  end

  def destroy
    find_coupon
    @coupon.destroy
    respond_with :admin, @coupon
  end

  private
  def find_coupon
    @coupon = Coupon.find params[:id]
  end
end
