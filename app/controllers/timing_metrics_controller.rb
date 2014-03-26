class TimingMetricsController < ApplicationController
  before_filter :authenticate_user!
  respond_to    :json

  def sftp_connection
    duration  = params[:duration].to_i
    box       = Box.where(id: params[:box_id].to_i).first

    if duration > 0 && box.present?
      region   = box.region.name
      host     = box.host

      if duration > 0 && region
        DatadogEmitPointJob.submit_job('nitrous_io.sftp_connection.timing',
                                       duration,
                                       tags: [Rails.env, "region:#{region}"],
                                       host: host)
      end
    end

    respond_with true, location: nil, status: 200
  end
end
