class PublicKeysController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_public_key, only: [:destroy]
  respond_to :json

  def index
    @public_keys = current_user.public_keys
    respond_with @public_keys
  end

  def create
    attrs = (params[:public_key] || {}).slice(:name, :key)
    @public_key = PublicKey.new(attrs)
    @public_key.user = current_user
    if @public_key.save
      METRICS.increment "ssh_keys.created"
      PublicKeyMailer.delay.save_key current_user.email,
        @public_key.name, @public_key.md5_fingerprint
    end
    respond_with @public_key
  end

  def destroy
    @public_key.destroy
    METRICS.increment "ssh_keys.deleted"
    respond_with @public_key
  end

  def import_github_keys
    PublicKey.enqueue_import_github_keys(current_user)
    METRICS.increment "ssh_keys.import_github"
    render nothing: true, status: :no_content
  end

  private
  def find_public_key
    @public_key = current_user.public_keys.find(params[:id])
  end
end
