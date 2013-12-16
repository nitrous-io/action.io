# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
ActionIO::Application.config.secret_token = ENV['SECRET_TOKEN']

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.
# ActionIO::Application.config.secret_key_base = '8074f419f5e43323ae9f3587356245cc9dd2ca3746126a12c9afa9d740e6a3719261bc854c77280a656e91ca108c7b0c84dfdd13ff351cc054fdc95737d1191c'
