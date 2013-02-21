class Admin::InvitesController < AdminController
  layout 'dashboard'

  def index
    @filter = params[:filter]

    @invites = if params.has_key?(:q) && params[:q].length > 3
      Invite.where("(city = ? OR country = ? OR email = ?)", params[:q], params[:q], params[:q]).
             paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
    else
      Invite.where("id > 0")
    end

    @invites = if @filter.blank? || @filter == 'pending'
      @invites.pending
    elsif @filter == 'activated'
      @invites.activated
    elsif @filter == 'accepted'
      @invites.accepted
    end.order('created_at DESC').paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def send_invite
    return_url = params[:return_url] || invites_url

    @invite = Invite.find params[:id]
    @invite.activate! if @invite.state == 'pending' && @invite.state != 'accepted'
    Notifier.delay.send_invite(@invite.id)
    TrackMixpanelEventJob.submit_job('Invite Sent', nil, email: @invite.email)

    flash[:notice] = 'Your invite was sent.'
    redirect_to return_url
  end
end
