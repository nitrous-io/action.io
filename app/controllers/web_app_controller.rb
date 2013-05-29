class WebAppController < ApplicationController
  before_filter :authenticate_user!
  before_filter :mark_invites_as_accepted, only: :index

  layout 'basic'

  def index
    @boxes = current_user.visible_boxes
    @regions = Region.enabled
    @box_templates = BoxTemplate.all
  end

  def hide_ide_tour
    current_user.update_attribute :hide_ide_tour, true
    render json: { status: 'ok' }, status: 200
  end

  def hide_boxes_tour
    current_user.update_attribute :hide_boxes_tour, true
    render json: { status: 'ok' }, status: 200
  end

  protected
  # If a user is already signed in, and we've approved his invite
  # his invite will be in the activated state
  # but when he starts to use the IDE, his state will become 'accepted'
  def mark_invites_as_accepted
    current_user.received_invites.where("state = ?", 'activated').each do |i|
      i.accept!
    end
  end
end
