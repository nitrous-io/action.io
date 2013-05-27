# coding: utf-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

admin = User.find_by_username 'admin'

unless admin
  i = Invite.new
  i.email = 'admins@nitrous.io'
  i.save
  i.activate!

  pw = SecureRandom.base64(12)
  admin = User.create username: 'admin', email: 'admins@nitrous.io', password: pw, password_confirmation: pw, invite_code: i.invite_code
  admin.admin = true
  admin.save!
end

mac_app_name = 'Nitrous.IO for Mac'
if Doorkeeper::Application.where(name: mac_app_name).count == 0
  mac_app = Doorkeeper::Application.new name: mac_app_name, redirect_uri: "https://#{Settings.host_full}/oauth_response.html"
  mac_app.owner = admin
  if Rails.env.development?
    mac_app.uid = 'c311fe81d0d94036502b8d23540c6a6545ef1943c856fbd79d898bb1ace15907'
    mac_app.secret = '7f227c8ea33dc87d3e494be6d497028cd89b582a2d7635cc81621f79329ef750'
  end
  mac_app.save!
end

windows_app_name = 'Nitrous.IO for Windows'
if Doorkeeper::Application.where(name: windows_app_name).count == 0
  windows_app = Doorkeeper::Application.new name: windows_app_name, redirect_uri: "https://#{Settings.host_full}/oauth_response.html"
  windows_app.owner = admin
  if Rails.env.development?
    windows_app.uid = 'c9acd5e36d122154ca2087b001fedd262991dbf65b8672000c0254556334cf06'
    windows_app.secret = 'f7b71c647d623956cb803b55607a9b8397bf72384bd81a1936346c29109a46ac'
  end
  windows_app.save!
end

linux_app_name = 'Nitrous.IO for Linux'
if Doorkeeper::Application.where(name: linux_app_name).count == 0
  linux_app = Doorkeeper::Application.new name: linux_app_name, redirect_uri: "https://#{Settings.host_full}/oauth_response.html"
  linux_app.owner = admin
  if Rails.env.development?
    linux_app.uid = '2d380b45efd4f76005d2ce3e4dddc30ca4765f3d284bca64b62597f2649e1e95'
    linux_app.secret = '418e3e67fb27f68bdc21ab6e480e89a38fbc4a4a7e90b8f38462f059df2ad6de'
  end
  linux_app.save!
end

vagrant_name = 'Vagrant'
if Doorkeeper::Application.where(name: vagrant_name).count == 0
  vagrant = Doorkeeper::Application.new name: vagrant_name, redirect_uri: "https://#{Settings.host_full}/oauth_response.html"
  vagrant.owner = admin
  if Rails.env.development?
    vagrant.uid = '0f53c0c1dc8f85c250b92ace97b3608256b20ff0feff116a63df241301513fd5'
    vagrant.secret = '0e5138e61c65a7f259b23a1b0c6161e67440d44d41160a36deac1b64d792bc17'
  end
  vagrant.save!
end

if BoxTemplate.count == 0
  BoxTemplate.create name: 'Ruby/Rails',    description: 'Ruby/Rails',    runtime: 'rails',  enabled: true,   admin: false
  BoxTemplate.create name: 'Node.js',       description: 'Node.js',       runtime: 'nodejs', enabled: true,   admin: false
  BoxTemplate.create name: 'Python/Django', description: 'Python/Django', runtime: 'django', enabled: true,   admin: false
  BoxTemplate.create name: 'Go',            description: 'Go',            runtime: 'go',     enabled: true,   admin: false
end

if Region.count == 0
  us_west_1      = Region.create name: 'us-west-1',      description: 'US West (N. California)',    coach_uri: 'https://coach-usw1.nitrous.io',   box_server_uri: 'https://rainbow-usw1.nitrous.io'
  us_west_2      = Region.create name: 'us-west-2',      description: 'US West (Oregon)',           coach_uri: 'https://coach-usw2.nitrous.io',   box_server_uri: 'https://rainbow-usw2.nitrous.io'
  us_east_1      = Region.create name: 'us-east-1',      description: 'US East (Virginia)',         coach_uri: 'https://coach-use1.nitrous.io',   box_server_uri: 'https://rainbow-use1.nitrous.io'
  eu_west_1      = Region.create name: 'eu-west-1',      description: 'Western Europe (Ireland)',   coach_uri: 'https://coach-euw1.nitrous.io',   box_server_uri: 'https://rainbow-euw1.nitrous.io'
  ap_southeast_1 = Region.create name: 'ap-southeast-1', description: 'Southeast Asia (Singapore)', coach_uri: 'https://coach-apse1.nitrous.io',  box_server_uri: 'https://rainbow-apse1.nitrous.io'
  ap_southeast_2 = Region.create name: 'ap-southeast-2', description: 'Australia (Sydney)',         coach_uri: 'https://coach-apse2.nitrous.io',  box_server_uri: 'https://rainbow-apse2.nitrous.io'
  ap_northeast_1 = Region.create name: 'ap-northeast-1', description: 'East Asia (Tokyo)',          coach_uri: 'https://coach-apne1.nitrous.io',  box_server_uri: 'https://rainbow-apne1.nitrous.io'
  sa_east_1      = Region.create name: 'sa-east-1',      description: 'South America (São Paulo)',  coach_uri: 'https://coach-sae1.nitrous.io',   box_server_uri: 'https://rainbow-sae1.nitrous.io'
end

if Plan.count == 0
  free = Plan.create name: 'Free'  , active: true  , price_cents: 0    , num_boxes: 1 , ram: 384  , disk_space: 1024  , ssh_access: false , sleepless: false
  new  = Plan.create name: 'New'   , active: false , price_cents: 0    , num_boxes: 1 , ram: 384  , disk_space: 1024  , ssh_access: true  , sleepless: true
  c4   = Plan.create name: '4-Cyl' , active: true  , price_cents: 995  , num_boxes: 3 , ram: 384  , disk_space: 2048  , ssh_access: true  , sleepless: true
  v6   = Plan.create name: 'V6'    , active: true  , price_cents: 1995 , num_boxes: 5 , ram: 512  , disk_space: 5120  , ssh_access: true  , sleepless: true
  v8   = Plan.create name: 'V8'    , active: true  , price_cents: 3995 , num_boxes: 5 , ram: 1024 , disk_space: 10240 , ssh_access: true  , sleepless: true
  v12  = Plan.create name: 'V12'   , active: true  , price_cents: 7995 , num_boxes: 5 , ram: 2048 , disk_space: 20480 , ssh_access: true  , sleepless: true
end
