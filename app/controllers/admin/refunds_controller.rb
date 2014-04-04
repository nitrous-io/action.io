class Admin::RefundsController < AdminController
  respond_to :html

  def index
    @refunds = Refund.order('created_at DESC')
    respond_with :admin, @refunds
  end

  def find_charges
    if params[:identifier].present?
      @user = User.where('email = :identifier OR username = :identifier', identifier: params[:identifier].downcase).first

      if @user.stripe_customer_id
        @charges = Stripe::Charge.all(customer: @user.stripe_customer_id).reject {|charge| !charge.paid }
      end
    end
  end

  def new
    @refund = Refund.new
    @refund.user_id = params[:user_id]
    @refund.stripe_charge_id = params[:stripe_charge_id]
    @refund.amount_in_cents = params[:amount_in_cents]
    respond_with :admin, @refund
  end

  def create
    @refund = Refund.new params[:refund]

    if @refund.process!
      redirect_to admin_refunds_path
    else
      render :new, user_id: @refund.user_id, stripe_charge_id: @refund.stripe_charge_id, amount: @refund.amount
    end
  end
end
