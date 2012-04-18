class PusherController < ApplicationController
  protect_from_forgery :except => [:auth]

  def auth
    channel_name = params[:channel_name]
    socket_id = params[:socket_id]
    if channel_name.starts_with?('private-user-') && user_signed_in? &&
       current_user.id.to_s == channel_name[/private-user-(\d+)/, 1]
      response = Pusher[params[:channel_name]].authenticate(params[:socket_id])
      render json: response and return
    end
    render text: 'Not authorized', status: '403'
  end
end
