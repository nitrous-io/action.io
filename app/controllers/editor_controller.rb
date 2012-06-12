class EditorController < ApplicationController
  before_filter :authenticate_user!
  layout 'basic'

  def index
    @box = current_user.boxes.first
  end
end
