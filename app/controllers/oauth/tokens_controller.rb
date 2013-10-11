class Oauth::TokensController < Doorkeeper::TokensController
  def create
    # monkey patch create method to return resource_owner_id as well
    response = strategy.authorize
    self.headers.merge! response.headers
    self.response_body = (response.respond_to?(:token) ? response.body.merge(resource_owner_id: response.token.resource_owner_id) : response.body).to_json
    self.status        = response.status
  rescue Doorkeeper::Errors::DoorkeeperError => e
    handle_token_exception e
  end
end
