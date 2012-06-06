class EditorController < ApplicationController
  before_filter :authenticate_user!

  def index
    @box = current_user.boxes.first
  end
end
