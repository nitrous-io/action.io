# Refers to secure_headers README for configurations
# https://github.com/twitter/secureheaders
::SecureHeaders::Configuration.configure do |config|
  config.hsts = { max_age: 20.years.to_i, include_subdomains: true}
  # so we can display our framed terminal page
  config.x_frame_options = 'SAMEORIGIN'
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = {value: 1, mode: 'block'}
  # dont use csp for now
  config.csp = false
end
