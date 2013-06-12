class InvitesController < ApplicationController
  before_filter :authenticate_user!, only: [:create, :index]
  respond_to :json

  def index
    @invites = current_user.owned_invites
    respond_with @invites
  end

  def create
    user_invitation = UserInvitation.new current_user
    @invite = user_invitation.invite params[:invite][:email]
    if @invite == UserInvitation::NO_INVITE_LEFT
      render json: { error: 'no invites left' }, status: :unprocessable_entity
    else
      if @invite.persisted?
        TrackMixpanelEventJob.submit_job('Invite Sent', current_user.id)
        IncrementMixpanelPropertyJob.submit_job(current_user.id, :invites_sent, 1)

        respond_with @invite
      else
        render json: { error: 'invalid invite request' }, status: :unprocessable_entity
      end
    end
  end
end
