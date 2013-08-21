class SubscriptionsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def create
    # retrieve exisiting billing profile
    # create one if one doesn't exist
    # use the stripe id in billing profile to create a new subscription
    #  - subscription should bill users on the 1st of every month.
  end
end
