class Api::V0::UsersController < Api::V0::BaseController
  doorkeeper_for :all, scopes: [:user], except: [:sign_in_token]
  doorkeeper_for :sign_in_token, scopes: [:web]

  before_filter :no_cache, only: [:sign_in_token]

  def show
    source = request.user_agent.match(/^ActionIO/) ? ActionUserAgentParser.parse(request.user_agent) : {}

    TrackMixpanelEventJob.submit_job('User Signed In', current_user.id, source)
    respond_with current_user
  end

  def sign_in_token
    respond_with sign_in_token: AuthToken.generate(current_user, 'sign_in')
  end
end
