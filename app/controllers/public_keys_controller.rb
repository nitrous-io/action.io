class PublicKeysController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_public_key, only: [:show, :update, :destroy]
  respond_to :json

  def index
    @public_keys = current_user.public_keys
    respond_with @public_keys
  end

  def create
    @public_key = PublicKey.new params.slice(:name, :key)
    @public_key.user = current_user
    @public_key.save
    respond_with @public_key
  end

  def show
    respond_with @public_key
  end

  def update
    @public_key.update_attributes params.slice(:name, :key)
    respond_with @public_key
  end

  def destroy
    @public_key.destroy
    respond_with @public_key
  end

  private
  def find_public_key
    @public_key = current_user.public_keys.find(params[:id])
  end
end
