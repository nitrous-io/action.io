class TimingMetricsController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  before_filter :authenticate_user!

  respond_to :json

  # Time it took for Web IDE to establish the SFTP connection.
  # params: duration (in milliseconds)
  #         region
  #         host
  def sftp_connection
    duration = sanitize(params[:duration])
    region   = sanitize(params[:region])
    host     = sanitize(params[:host])

    # We'll need to POST the following metric to DD:
    #   nitrous_io.sftp_connection.timing
    # with tags region:#{region}, host:#{host}
    metric = 'nitrous_io.sftp_connection.timing'

    Datadog.delay.emit_point(metric, duration, host: host, tags: [Rails.env, "region:#{region}"])
  end
end
