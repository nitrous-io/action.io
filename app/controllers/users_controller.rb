class UsersController < ApplicationController
  before_filter :authenticate_user!

  respond_to :json

  def intro_seen
    current_user.intro_seen = true
    current_user.save!
    render nothing: true, status: :no_content
  end
end
