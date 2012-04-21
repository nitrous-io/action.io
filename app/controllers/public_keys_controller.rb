class PublicKeysController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_public_key, only: [:show, :destroy]
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

  def destroy
    @public_key.destroy
    respond_with @public_key
  end

  def import_github_keys
    PublicKey.enqueue_import_github_keys(current_user)
    render nothing: true, status: :no_content
  end

  private
  def find_public_key
    @public_key = current_user.public_keys.find(params[:id])
  end
end
