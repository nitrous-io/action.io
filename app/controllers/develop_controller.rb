class DevelopController < ApplicationController
  skip_before_filter :check_user_login_status, only: [:index, :embed]
  before_filter :authenticate_user!, except: [:index, :embed]
  layout 'guest'

  NEW_BOX_PATH = '/app#/intro/create'.freeze
  PICK_BOX_PATH = '/app#/boxes/clone_repo_picker'.freeze

  # TODO if url is empty, we should allow users to enter their own repo URL.
  def index
    @url = Sanitize.clean(params[:url])
    @template_name = Sanitize.clean(params[:template_name])
    @file_to_open = Sanitize.clean(params[:file_to_open])

    intent_params = { url: @url, template_name: @template_name, file_to_open: @file_to_open }

    mixpanel_attributes = intent_params
    mixpanel_attributes[:source] = Sanitize.clean(params[:source]) if params[:source].present?
    TrackMixpanelEventJob.submit_job("Visited Develop Page", current_user.try(:id), mixpanel_attributes)

    # TODO This should probably be an Intent model.
    intent = {
      kind: 'clone_repo',
      data: intent_params
    }.to_query

    if signed_in?
      # FIXME The reason we use User#intent instead of trying to use a query
      # param or something like /boxes/clone_repo/:url, is that those just
      # don't work in the version of Ember we're using.
      current_user.intent = intent
      current_user.save!

      if current_user.visible_boxes.blank?
        redirect_to NEW_BOX_PATH
      else
        redirect_to PICK_BOX_PATH
      end
      return
    end

    @sign_up_path = new_user_registration_path(intent: intent)
    @sign_in_path = new_user_session_path(redirect_to: develop_path(intent_params))

    render 'index', layout: 'bare'
  end

  def embed
  end
end
