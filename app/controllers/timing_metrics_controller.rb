class TimingMetricsController < ApplicationController
  before_filter :authenticate_user!
  respond_to    :json

  def sftp_connection
    duration = params[:duration].to_i
    region   = Region.where(name: params[:region]).first
    host     = Sanitize.clean(params[:host].to_s)

    if duration > 0 && region
      DatadogEmitPointJob.submit_job('nitrous_io.sftp_connection.timing',
                                     duration,
                                     tags: [Rails.env, "region:#{region.name}"],
                                     host: host)
    end

    respond_with true, location: nil, status: 200
  end
end
