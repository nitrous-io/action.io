module BasicAuthSpecHelper
  def basic_auth(name, password)
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(name, password)
  end
end
