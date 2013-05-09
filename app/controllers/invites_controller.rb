class InvitesController < ApplicationController
  before_filter :authenticate_user!, only: [:create, :index]
  layout 'dashboard'

  def index
    @invites = current_user.owned_invites.order('created_at DESC').
      paginate(page: params[:page] || 1, per_page: 20)
  end

  def create
    user_invitation = UserInvitation.new current_user
    @invite = user_invitation.invite params[:invite][:email]
    if @invite == UserInvitation::NO_INVITE_LEFT
      flash[:notice] = "Looks like you don't have any invites left"
    else
      if @invite.persisted?
        flash[:notice] = "Invite has been sent to #{@invite.email}"
        TrackMixpanelEventJob.submit_job('Invite Sent', current_user.id)
        IncrementMixpanelPropertyJob.submit_job(current_user.id, :invites_sent, 1)
      else
        flash[:notice] = "Looks like you entered an invalid invite, please try again"
      end
    end
    redirect_to invites_path
  end
end
