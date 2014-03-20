class TimingMetricsController < ApplicationController
  before_filter :authenticate_user!
  respond_to    :json

  # Time it took for Web IDE to establish the SFTP connection.
  # params: duration (in milliseconds)
  #         region
  #         host
  def sftp_connection
    duration = params[:duration].to_i
    region   = Region.where(name: params[:region]).first

    if duration > 0 && region
      DatadogEmitPointJob.submit_job('nitrous_io.sftp_connection.timing',
                                     duration,
                                     tags: [Rails.env, "region:#{region.name}"])
    end

    respond_with true, location: nil, status: 200
  end
end
