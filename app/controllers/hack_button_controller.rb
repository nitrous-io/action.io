class HackButtonController < ApplicationController
  skip_before_filter :check_user_login_status, only: [:index, :embed]
  layout 'guest'

  NEW_BOX_PATH = '/app#/intro/create_box'.freeze
  PICK_BOX_PATH = '/app#/hack'.freeze

  GITHUB_REPO_REGEX = /\A([a-zA-Z\d\-_]+)\/([a-zA-Z\d\-_.]+)\z/

  def index
    @repo = Sanitize.clean(params[:repo].to_s)
    runtime = Sanitize.clean(params[:runtime].to_s)
    file_to_open = Sanitize.clean(params[:file_to_open].to_s)

    if runtime.blank? || @repo.blank? ||
      (@repo.present? && !@repo.to_s.match(GITHUB_REPO_REGEX)) || # is github repo name valid?
      (runtime.present? && !BoxTemplate.where(runtime: runtime.to_s).any?) # does given runtime exist?
      redirect_to root_url and return
    end

    url = "https://github.com/#{@repo}"
    repo_params = {
      hack_repo: @repo,
      hack_runtime: runtime,
      hack_file_to_open: file_to_open,
      hack_repo_url: url,
    }

    if signed_in?
      mixpanel_attributes = { url: url, runtime: runtime, file_to_open: file_to_open, repo: @repo }
      mixpanel_attributes[:source] = Sanitize.clean(params[:source]) if params[:source].present?
      TrackMixpanelEventJob.submit_job("Visited Hack Button Page", current_user.id, mixpanel_attributes)

      if current_user.visible_boxes.blank?
        redirect_to EmberJS.route(NEW_BOX_PATH, repo_params)
      else
        redirect_to EmberJS.route(PICK_BOX_PATH, repo_params)
      end

      return
    end

    repo_params.each do |k, v|
      cookies[k] = v
    end

    @sign_up_path = new_user_registration_path
    @sign_in_path = new_user_session_path(redirect_to: hack_button_path(params))

    render 'index', layout: 'guest', locals: { no_footer: true, no_nav: true }
  end

  def embed
    @box_templates = BoxTemplate.all
  end
end
