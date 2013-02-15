# coding: utf-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

admin = User.find_by_username 'admin'

unless admin
  i = Invite.new
  i.email = 'admins@action.io'
  i.save
  i.activate!

  pw = SecureRandom.base64(12)
  admin = User.create username: 'admin', email: 'admins@action.io', password: pw, password_confirmation: pw, invite_code: i.invite_code
  admin.admin = true
  admin.save!
end

if Doorkeeper::Application.count == 0
  mac_app = Doorkeeper::Application.new name: 'Action.IO for Mac', redirect_uri: "https://#{Settings.host_full}/oauth_response.html"
  mac_app.owner = admin
  if Rails.env.development?
    mac_app.uid = 'c311fe81d0d94036502b8d23540c6a6545ef1943c856fbd79d898bb1ace15907'
    mac_app.secret = '7f227c8ea33dc87d3e494be6d497028cd89b582a2d7635cc81621f79329ef750'
  end
  mac_app.save!
end

if BoxTemplate.count == 0
  BoxTemplate.create name: 'Ruby/Rails',    description: 'Ruby/Rails',    runtime: 'rails',  enabled: true,   admin: false
  BoxTemplate.create name: 'Node.js',       description: 'Node.js',       runtime: 'nodejs', enabled: true,   admin: false
  BoxTemplate.create name: 'Python/Django', description: 'Python/Django', runtime: 'django', enabled: true,   admin: false
  BoxTemplate.create name: 'Go',            description: 'Go',            runtime: 'go',     enabled: true,   admin: false
end

if Region.count == 0
  us_west_1      = Region.create name: 'us-west-1',      description: 'US West (N. California)',    coach_uri: 'https://coach-usw1.action.io',   box_server_uri: 'https://rainbow-usw1.action.io'
  us_west_2      = Region.create name: 'us-west-2',      description: 'US West (Oregon)',           coach_uri: 'https://coach-usw2.action.io',   box_server_uri: 'https://rainbow-usw2.action.io'
  us_east_1      = Region.create name: 'us-east-1',      description: 'US East (Virginia)',         coach_uri: 'https://coach-use1.action.io',   box_server_uri: 'https://rainbow-use1.action.io'
  eu_west_1      = Region.create name: 'eu-west-1',      description: 'Western Europe (Ireland)',   coach_uri: 'https://coach-euw1.action.io',   box_server_uri: 'https://rainbow-euw1.action.io'
  ap_southeast_1 = Region.create name: 'ap-southeast-1', description: 'Southeast Asia (Singapore)', coach_uri: 'https://coach-apse1.action.io',  box_server_uri: 'https://rainbow-apse1.action.io'
  ap_southeast_2 = Region.create name: 'ap-southeast-2', description: 'Australia (Sydney)',         coach_uri: 'https://coach-apse2.action.io',  box_server_uri: 'https://rainbow-apse2.action.io'
  ap_northeast_1 = Region.create name: 'ap-northeast-1', description: 'East Asia (Tokyo)',          coach_uri: 'https://coach-apne1.action.io',  box_server_uri: 'https://rainbow-apne1.action.io'
  sa_east_1      = Region.create name: 'sa-east-1',      description: 'South America (São Paulo)',  coach_uri: 'https://coach-sae1.action.io',   box_server_uri: 'https://rainbow-sae1.action.io'
end

