class FreighterController < ApplicationController
  protect_from_forgery except: [:webhook]
  before_filter :authenticate_freighter!, only: [:webhook]

  def webhook
    case state_params[:op]
    when 'provision'
      provision_box
    end
    render nothing: true, status: :ok
  end

  protected

  def provision_box
    state = state_params
    # TODO validate assumptions
    box = Box.find(state[:box_id])
    box.container_uid = params[:container][:id]
    box.port = params[:container][:ssh_port]
    box.save!
  end

  def state_params
    Freighter.state_string_to_params params[:state]
  end

  def authenticate_freighter!
    # TODO
  end
end
