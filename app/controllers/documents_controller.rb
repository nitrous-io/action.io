class DocumentsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_box
  respond_to :json

  def index
    @documents = Document.opened @box.id, current_user.id
    respond_with @documents
  end

  protected
  def find_box
    @box = current_user.boxes.find(params[:box_id])
  end
end
