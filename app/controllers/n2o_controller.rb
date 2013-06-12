class N2oController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def index
    json = { n2o: { max: current_user.max_n2o, used: current_user.used_n2o } }
    respond_with json
  end
end
