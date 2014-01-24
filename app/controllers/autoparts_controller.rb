class AutopartsController < ApplicationController
  def webhook
    type = params[:type]
    box = Box.find_by id: params[:box_id]

    if type && box
      # Notify to update the IDE using shover
      box.users.pluck('users.id').each do |user_id|
        Shover.publish user_id, 'aio:parts_changed', { box_id: box.id }
      end

      # Track the event in Mixpanel
      # Since we can't track the exact user who ran the command, track the event with the box owner.
      TrackMixpanelEventJob.submit_job "Autopart #{type.capitalize}", box.owner.id, { part: params[:part_name], part_version: params[:part_version], autoparts_version: params[:autoparts_version] }
    end

    render nothing: true, status: :ok
  end
end
