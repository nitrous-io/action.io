class MacController < ApplicationController
  layout 'basic'

  def index
    TrackMixpanelEventJob.submit_job('Visited Mac App Homepage', current_user.try(:id))
  end

  def appcast
    @mac_app_updates = MacAppUpdate.published
    render 'appcast', formats: [:xml]
  end

  def download
    TrackMixpanelEventJob.submit_job('Mac App Downloaded', current_user.try(:id))
    redirect_to MacAppUpdate.latest_url
  end

  def release_notes
    if mac_app_update = MacAppUpdate.select(:release_notes).find_by_version(params[:version].to_s)
      render text: mac_app_update.release_notes_in_html
    else
      render text: 'Not Found', status: :not_found
    end
  end
end
