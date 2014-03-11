class TimingMetricsController < ApplicationController
  before_filter :authenticate_user!

  respond_to :json

  # Time it took for Web IDE to establish the SFTP connection.
  # params: duration (in milliseconds)
  def sftp_connection
    # TODO: grab user, box
    # then do something useful with the data
    # eg. knowing user's location and box's region can be useful?
    render json: { status: 'ok' }, status: 200
  end
end
