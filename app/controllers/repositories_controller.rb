class RepositoriesController < ApplicationController
  skip_before_filter :check_user_login_status
  layout 'bare'

  NEW_BOX_PATH = '/app#/intro/create'.freeze
  PICK_BOX_PATH = '/app#/boxes/clone_repo_picker'.freeze

  # TODO if url is empty, we should allow users to enter their own repo URL.
  def clone
    @url = Sanitize.clean(params[:url])

    if signed_in?
      if current_user.visible_boxes.blank?
        redirect_to NEW_BOX_PATH
      else
        redirect_to PICK_BOX_PATH
      end
      return
    end

    @sign_up_path = new_user_registration_path(intent: { kind: 'clone_repo', data: { url: @url } }.to_query)
    @sign_in_path = new_user_session_path(redirect_to: clone_repository_path(url: @url))
  end
end
