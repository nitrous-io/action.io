class PusherController < ApplicationController
  protect_from_forgery except: [:auth]
  doorkeeper_for :auth, if: -> { oauth_token_present? }, scopes: [:push]

  def auth
    channel_name = params[:channel_name]
    socket_id = params[:socket_id]
    if channel_name.starts_with?('private-user-') && authenticated_user &&
       authenticated_user.id.to_s == channel_name[/private-user-(\d+)/, 1]
      response = Pusher[params[:channel_name]].authenticate(params[:socket_id])
      render json: response and return
    end
    render text: 'Not authorized', status: '403'
  end

  private
  def authenticated_user
    current_user || (User.find_by_id doorkeeper_token.resource_owner_id if doorkeeper_token)
  end
end
