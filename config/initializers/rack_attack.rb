# Throttle login attempts for a given login parameter to 6 reqs per 30 minutes
# Return the email as a discriminator on POST /users/sign_in requests
Rack::Attack.throttle('sign_in/login', limit: 6, period: 30.minutes) do |req|
  req.params['user']['login'] if req.path == '/users/sign_in' && req.post?
end

# Throttle metrics collection for a given login parameter to 10 reqs per minute
# Return the box_id as a discriminator on POST /timing/sftp_connection requests
Rack::Attack.throttle('timing/sftp_connection', limit: 10, period: 1.minute) do |req|
  req.params['box_id'] if req.path == '/timing/sftp_connection' && req.post?
end
