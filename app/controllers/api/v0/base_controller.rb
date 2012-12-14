class Api::V0::BaseController < ApplicationController
  include CurrentUserFromDoorkeeperToken

  respond_to :json
end
