class FirebaseController < ApplicationController
  before_filter :no_cache, only: [:auth_token]
  before_filter :authenticate_user!
  before_filter :find_box, except: [:index, :create, :webhook, :touch]

  respond_to :json

  def auth_token
    firebase_secret_token = ENV['FIREBASE_SECRET_TOKEN']

    unless firebase_secret_token
      logger.info "Please set the FIREBASE_SECRET_TOKEN in the environment"
      raise "Firebase secret token not found."
    end

    options = { admin: current_user.admin? }
    auth_data = { user_id: current_user.to_param, box_id: @box.to_param }

    generator = Firebase::FirebaseTokenGenerator.new firebase_secret_token
    token = generator.create_token(auth_data, options)

    render json: { auth_token: token }
  end

  protected
  def find_box
    @box = current_user.boxes.find(params[:box_id])
  end
end
