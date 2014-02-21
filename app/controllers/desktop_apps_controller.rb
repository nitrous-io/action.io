class DesktopAppsController < ApplicationController
  layout 'basic'

  def index
    TrackMixpanelEventJob.submit_job("Visited Desktop App Homepage", current_user.try(:id))
  end

  def appcast
    @app_updates = AppUpdate.where(platform: params[:platform].to_s).published
    @platform = params[:platform].to_s.capitalize
    render 'appcast', formats: [:xml]
  end

  def download
    platform = params[:platform].to_s
    TrackMixpanelEventJob.submit_job("#{platform.capitalize} App Downloaded", current_user.try(:id))
    SetMixpanelPropertyJob.submit_job(current_user.id, "downloaded_#{platform}_app", true) if current_user
    redirect_to AppUpdate.latest_url(platform)
  end

  def release_notes
    if app_update = AppUpdate.select(:release_notes).find_by_version_and_platform(params[:version].to_s, params[:platform].to_s)
      render text: app_update.release_notes_in_html
    else
      render text: 'Not Found', status: :not_found
    end
  end
end
