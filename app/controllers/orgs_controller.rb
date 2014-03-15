class OrgsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def create
    org_params = params[:org] || {}

    @org = Org.new
    @org.name           = org_params[:name]
    @org.billing_email  = org_params[:billing_email]

    if @org.save
      IncrementMixpanelPropertyJob.submit_job(current_user.id, :orgs, 1)
      TrackMixpanelEventJob.submit_job('Org Created', current_user.id)
    end

    respond_with @org, location: nil
  end
end
