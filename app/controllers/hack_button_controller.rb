class HackButtonController < ApplicationController
  skip_before_filter :check_user_login_status, only: [:index, :embed]
  layout 'guest'

  NEW_BOX_PATH = '/app#/intro/create'.freeze
  PICK_BOX_PATH = '/app#/boxes/clone_repo_picker'.freeze

  GITHUB_REPO_REGEX = /\A([a-zA-Z\d\-_]+)\/([a-zA-Z\d\-_.]+)\z/

  # TODO if url is empty, we should allow users to enter their own repo URL.
  def index
    runtime = Sanitize.clean(params[:runtime].to_s)
    @repo = Sanitize.clean(params[:repo].to_s)
    file_to_open = Sanitize.clean(params[:file_to_open].to_s)

    if runtime.blank? || @repo.blank? ||
      (@repo.present? && !@repo.to_s.match(GITHUB_REPO_REGEX)) || # is github repo name valid?
      (runtime.present? && !BoxTemplate.where(runtime: runtime.to_s).any?) # does given runtime exist?
      redirect_to root_url and return
    end

    url = "https://github.com/#{@repo}.git"

    intent_params = { url: url, runtime: runtime, file_to_open: file_to_open, repo: @repo }

    mixpanel_attributes = intent_params.dup
    mixpanel_attributes[:source] = Sanitize.clean(params[:source]) if params[:source].present?

    # TODO This should probably be an Intent model.
    intent = {
      kind: 'clone_repo',
      data: intent_params
    }.to_query

    if signed_in?
      TrackMixpanelEventJob.submit_job("Visited Hack Button Page", current_user.id, mixpanel_attributes)
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
    @sign_in_path = new_user_session_path(redirect_to: hack_button_url(intent_params))

    render 'index', layout: 'guest', locals: { no_footer: true, no_nav: true }
  end

  def embed
    @box_templates = BoxTemplate.all
  end
end
