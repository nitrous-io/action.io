class IdeController < ApplicationController
  before_filter :authenticate_user!
  layout 'basic'

  def index
  end
end
