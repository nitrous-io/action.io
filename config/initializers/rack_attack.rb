# Throttle login attempts for a given login parameter to 6 reqs per 30 minutes
# Return the login (username/email) as a discriminator on POST /users/sign_in requests
Rack::Attack.throttle('sign_in/login', limit: 6, period: 30.minutes) do |req|
  req.params['user'] && req.params['user']['login'] if req.path == '/users/sign_in' && req.post?
end

# Throttle login attempts by ip to 5 reqs per 10 seconds
Rack::Attack.throttle('sign_in/ip', limit: 5, period: 10.seconds) do |req|
  req.ip if req.path == '/users/sign_in' && req.post?
end

# Throttle signup attempts by ip to 5 reqs per 60 seconds
# Prevents e-mail enumeration attacks
Rack::Attack.throttle('signup/ip', limit: 5, period: 60.seconds) do |req|
  req.ip if req.path == '/users' && req.post?
end

# Throttle reset password attempts by ip to 5 reqs per 5 minutes
# Prevents e-mail enumeration attacks
Rack::Attack.throttle('reset_password/ip', limit: 5, period: 5.minutes) do |req|
  req.ip if req.path == '/users/password' && req.post?
end

# Throttle confirmation attempts by ip to 5 reqs per 10 minutes
# Prevents e-mail enumeration attacks
Rack::Attack.throttle('request_confirmation/ip', limit: 5, period: 10.minutes) do |req|
  req.ip if req.path == '/users/confirmation' && req.post?
end

# Throttle metrics collection for a given login parameter to 10 reqs per minute
# Return the box_id as a discriminator on POST /timing/sftp_connection requests
Rack::Attack.throttle('timing/sftp_connection', limit: 10, period: 1.minute) do |req|
  req.params['box_id'] if req.path == '/timing/sftp_connection' && req.post?
end

# Throttle certain IPs that have a history of malfeasance.
Rack::Attack.throttle('requests/ip', limit: 10, period: 10.seconds) do |req|
  blacklisted_ips = %w(
    153.188.69.40
  )
  req.ip if blacklisted_ips.include?(req.ip)
end
