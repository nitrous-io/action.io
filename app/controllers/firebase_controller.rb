class FirebaseController < ApplicationController
  before_filter :no_cache, only: [:auth_token]
  before_filter :authenticate_user!

  respond_to :json

  def auth_token
    options = { admin: current_user.admin? }
    auth_data = { user_id: current_user.id }

    generator = Firebase::FirebaseTokenGenerator.new ENV['FIREBASE_SECRET_TOKEN']
    token = generator.create_token(auth_data, options)

    render json: { auth_token: token }
  end
end
