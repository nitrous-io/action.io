class InvitesController < ApplicationController
  before_filter :authenticate_user!, only: [:create, :index]
  respond_to :json

  def index
    @invites = current_user.owned_invites
    respond_with @invites
  end

  def create
    @invite = Invite.new.tap do |i|
      i.inviting_user = current_user
      i.email = params[:invite][:email]
      i.referral_code = current_user.referral_code
      i.save
    end

    if @invite.persisted?
      InviteMailer.delay.send_invite(@invite.id)

      TrackMixpanelEventJob.submit_job('Invite Sent', current_user.id)
      IncrementMixpanelPropertyJob.submit_job(current_user.id, :invites_sent, 1)
    end

    respond_with @invite
  end
end
