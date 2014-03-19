class TimingMetricsController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  before_filter :authenticate_user!

  respond_to :json

  # Time it took for Web IDE to establish the SFTP connection.
  # params: duration (in milliseconds)
  #         region
  def sftp_connection
    duration = sanitize(params[:duration])
    region   = sanitize(params[:region])

    # We'll need to POST the following metric to DD:
    #   nitrous_io.sftp_connection.timing
    # with tags region:#{region}
    metric = 'nitrous_io.sftp_connection.timing'

    begin
      Datadog.emit_point(metric, duration, tags: [Rails.env, "region:#{region}"])
      render json: { status: 'ok' }, status: 200
    rescue
      render json: { status: 'err' }, status: 500
    end
  end
end
