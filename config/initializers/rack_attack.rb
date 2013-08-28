# Throttle login attempts for a given login parameter to 6 reqs per 30 minutes
# Return the email as a discriminator on POST /users/sign_in requests
Rack::Attack.throttle('sign_in/login', limit: 6, period: 30.minutes) do |req|
  req.params['user']['login'] if req.path == '/users/sign_in' && req.post?
end
