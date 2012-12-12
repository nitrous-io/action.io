class DocumentsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_box
  before_filter :find_document, only: [:destroy, :update]
  respond_to :json

  def index
    @documents = Document.opened(@box.id, current_user.id).order(:created_at)
    respond_with @documents
  end

  def create
    @document = Document.new(document_params).tap do |d|
      d.box = @box
      d.user = current_user
    end
    @document.save
    respond_with @box, @document
  end

  def update
    @document.update_attributes document_params
    respond_with @document do |format|
      format.json do
        render json: {document: {id: @document.id}}
      end
    end
  end

  def destroy
    @document.destroy
    respond_with @box, @document
  end

  protected
  def find_box
    @box = current_user.boxes.find(params[:box_id])
  end

  def find_document
    @document = @box.documents.where(id: params[:id], user_id: current_user.id).first
    head :unauthorized and return unless @document
  end

  def document_params
    params[:document].slice :pathname, :content, :last_saved_content
  end
end
