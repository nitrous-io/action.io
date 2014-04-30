class HackButtonController < ApplicationController
  skip_before_filter :check_user_login_status, only: [:index, :embed]
  layout 'guest'

  GITHUB_REPO_REGEX = /\A([a-zA-Z\d\-_]+)\/([a-zA-Z\d\-_.]+)\z/

  def index
    @repo = Sanitize.clean(params[:repo].to_s)
    runtime = Sanitize.clean(params[:runtime].to_s)
    file_to_open = Sanitize.clean(params[:file_to_open].to_s)

    if @repo.blank? ||
      (@repo.present? && !@repo.to_s.match(GITHUB_REPO_REGEX)) # is github repo name valid?
      redirect_to root_url and return
    end

    if signed_in?
      url = "https://github.com/#{@repo}"
      repo_params = {
        hack_repo: @repo,
        hack_runtime: runtime,
        hack_file_to_open: file_to_open,
        hack_repo_url: url,
      }

      mixpanel_attributes = { url: url, runtime: runtime, file_to_open: file_to_open, repo: @repo }
      mixpanel_attributes[:source] = Sanitize.clean(params[:source]) if params[:source].present?
      TrackMixpanelEventJob.submit_job("Visited Hack Button Page", current_user.id, mixpanel_attributes)

      if current_user.visible_boxes.blank?
        redirect_to EmberJS.route('intro/create_box', repo_params)
      else
        redirect_to EmberJS.route('hack', repo_params)
      end

      return
    end

    current_path = hack_button_path(params)
    cookies[:hack] = current_path

    @sign_up_path = new_user_registration_path
    @sign_in_path = new_user_session_path(redirect_to: current_path)

    render 'index', layout: 'guest', locals: { no_footer: true, no_nav: true }
  end

  def embed
    @box_templates = BoxTemplate.all
  end
end
