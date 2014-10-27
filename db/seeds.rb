# coding: utf-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

# assumes 'name' is existing identifier
def maybe_create(klass, attributes={})
  record = klass.find_by_name(attributes[:name])
  return record if record
  klass.create(attributes)
end

admin = User.find_by_username 'admin'

unless admin
  pw = SecureRandom.base64(12)
  admin = User.create username: 'admin', email: 'admins@nitrous.io', password: pw, password_confirmation: pw
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

chrome_app_name = 'Nitrous.IO for Chrome'
if Doorkeeper::Application.where(name: chrome_app_name).count == 0
  chrome_app = Doorkeeper::Application.new name: chrome_app_name, redirect_uri: "https://#{Settings.host_full}/oauth_response.html"
  chrome_app.owner = admin
  if Rails.env.development?
    chrome_app.uid = '2aa25d507f263f954c331c57d04f3e147e39fdaf9c6c4e146d496e99b51ddfd6'
    chrome_app.secret = 'ac187c7e14fbd91943ba1350c62ec2cd85730ada36614a9f24fa831fc2de0b38'
  end
  chrome_app.save!
end

desktop_app_name = 'Nitrous Desktop'
if Doorkeeper::Application.where(name: desktop_app_name).count == 0
  desktop_app = Doorkeeper::Application.new name: desktop_app_name, redirect_uri: "https://#{Settings.host_full}/oauth_response.html"
  desktop_app.owner = admin
  if Rails.env.development?
    desktop_app.uid = '575b8c5a4eefa8d243a89fc1204315f106be895fc11f6d4fd4cd96a4efaa4d10'
    desktop_app.secret = '06273e99bc713d28ac628e2e79c2ac5d4de7742c1bb27e7560491b784fea5373'
  end
  desktop_app.save!
end

apt_repo_app_name = 'apt.nitrous.io'
if Doorkeeper::Application.where(name: apt_repo_app_name).count == 0
  apt_repo_app = Doorkeeper::Application.new name: apt_repo_app_name, redirect_uri: "https://#{Settings.host_full}/oauth_response.html"
  apt_repo_app.owner = admin
  apt_repo_app.save!
end

if BoxTemplate.count == 0
  BoxTemplate.create name: 'Ruby/Rails',    description: 'Ruby/Rails',    runtime: 'rails',  enabled: true, admin: false
  BoxTemplate.create name: 'Node.js',       description: 'Node.js',       runtime: 'nodejs', enabled: true, admin: false
  BoxTemplate.create name: 'Python/Django', description: 'Python/Django', runtime: 'django', enabled: true, admin: false
  BoxTemplate.create name: 'Go',            description: 'Go',            runtime: 'go',     enabled: true, admin: false
  BoxTemplate.create name: 'PHP',           description: 'PHP',           runtime: 'php',    enabled: true, admin: false
  BoxTemplate.create name: 'Meteor',        description: 'Meteor',        runtime: 'meteor', enabled: true, admin: false
end

us_west = maybe_create Region, name: 'us-west-1',      description: 'US West (N. California)', coach_uri: 'https://coach-usw1.nitrous.io',   box_server_uri: 'https://rainbow-usw1.nitrous.io', version: 'drogo', ssl_enabled: true
us_east = maybe_create Region, name: 'us-east-1',      description: 'US East',                 coach_uri: 'https://coach-use1.nitrous.io',   box_server_uri: 'https://rainbow-use1.nitrous.io',  version: 'drogo', ssl_enabled: true
eu_west = maybe_create Region, name: 'eu-west-1',      description: 'Western Europe',          coach_uri: 'https://coach-euw1.nitrous.io',   box_server_uri: 'https://rainbow-euw1.nitrous.io',  version: 'drogo', ssl_enabled: true
ap_southeast = maybe_create Region, name: 'ap-southeast-1', description: 'Southeast Asia',          coach_uri: 'https://coach-apse1.nitrous.io',  box_server_uri: 'https://rainbow-apse1.nitrous.io', version: 'drogo'
ap_northeast = maybe_create Region, name: 'ap-northeast-1', description: 'East Asia',               coach_uri: 'https://coach-apne1.nitrous.io',  box_server_uri: 'https://rainbow-apne1.nitrous.io', version: 'bran'
south_america = maybe_create Region, name: 'sa-east-1',      description: 'South America',           coach_uri: 'https://coach-sae1.nitrous.io',   box_server_uri: 'https://rainbow-sae1.nitrous.io',  version: 'cersei'
oceania = maybe_create Region, name: 'ap-southeast-2', description: 'Australia',               coach_uri: 'https://coach-apse2.nitrous.io',  box_server_uri: 'https://rainbow-apse2.nitrous.io', version: 'drogo'

maybe_create Region, name: 'us-west-2',      description: 'US West (Oregon)',        coach_uri: 'https://coach-usw2.nitrous.io',   box_server_uri: 'https://rainbow-usw2.nitrous.io',  version: 'drogo'

if Rails.env.development?
  Region.update_all coach_uri: 'http://www.n2odev.com:5002', box_server_uri: 'https://www.n2odev.com:5001'
  Region.update_all enabled: true
end

if (global_plan_group = PlanGroup.find_by_name(PlanGroup::DEFAULT_NAME)).nil?
  global_plan_group = PlanGroup.create name: PlanGroup::DEFAULT_NAME
end

if (team_plan_group = PlanGroup.find_by_name(PlanGroup::TEAM_NAME)).nil?
  team_plan_group = PlanGroup.create name: PlanGroup::TEAM_NAME
end

if Plan.count == 0
  start_plan = Plan.create name: 'Start', price: 7.95,  n2o_amount: 400,  interval: 'month', stripe_id: 'n2o_400',  cpu_multiplier: 1, vmem_multiplier: 1, memory: 2, storage: 16, features: [{"name" => "1 Box", "live" => true}, {"name" => "Boxes Never Shutdown", "live" => true}], display_order: 1
  shift_plan = Plan.create name: 'Shift', price: 19.95, n2o_amount: 1000, interval: 'month', stripe_id: 'n2o_1000', cpu_multiplier: 2, vmem_multiplier: 2, memory: 4, storage: 32, features: [{"name" => "3 Boxes", "live" => true}, {"name" => "Boxes Never Shutdown", "live" => true}, {"name" => "Custom Domains", "live" => true}], display_order: 2, highlight: true
  turbo_plan = Plan.create name: 'Turbo', price: 39.95, n2o_amount: 2000, interval: 'month', stripe_id: 'n2o_2000', cpu_multiplier: 2, vmem_multiplier: 2, memory: 8, storage: 64,  features: [{"name" => "5 Boxes", "live" => true}, {"name" => "Boxes Never Shutdown", "live" => true}, {"name" => "Custom Domains", "live" => true}], display_order: 3

  global_plan_group.plans << start_plan
  global_plan_group.plans << shift_plan
  global_plan_group.plans << turbo_plan
end

if team_plan_group.plans.count == 0
  small_plan  = Plan.create name: 'Small',   price: 79.95,   n2o_amount: 6000,  interval: 'month', stripe_id: 'n2o_6000',  cpu_multiplier: 1, vmem_multiplier: 1, memory: 1, storage: 20, display_order: 1, features: [{"name" => "5 Boxes", "live" => true}, {"name" => "Boxes Never Shutdown", "live" => true}, {"name" => "Box Snapshots", "live" => true }, {"name" => "Team Management", "live" => false}, {"name" => "Streamlined Dashboard", "live" => false}]
  medium_plan = Plan.create name: 'Medium',  price: 129.95,  n2o_amount: 12000, interval: 'month', stripe_id: 'n2o_12000', cpu_multiplier: 2, vmem_multiplier: 2, memory: 1, storage: 20, display_order: 2, features: [{"name" => "10 Boxes", "live" => true}, {"name" => "Boxes Never Shutdown", "live" => true}, {"name" => "Box Snapshots", "live" => true }, {"name" => "Team Management", "live" => false}, {"name" => "Streamlined Dashboard", "live" => false}]
  large_plan  = Plan.create name: 'Large',   price: 219.95,  n2o_amount: 25000, interval: 'month', stripe_id: 'n2o_25000', cpu_multiplier: 2, vmem_multiplier: 2, memory: 1, storage: 20, display_order: 3, features: [{"name" => "20 Boxes", "live" => true}, {"name" => "Boxes Never Shutdown", "live" => true}, {"name" => "Box Snapshots", "live" => true }, {"name" => "Team Management", "live" => false}, {"name" => "Streamlined Dashboard", "live" => false}]

  team_plan_group.plans << small_plan
  team_plan_group.plans << medium_plan
  team_plan_group.plans << large_plan
end

plan_1x = maybe_create BoxhostPlan, name: DedicatedBoxhost::TYPES::TYPE_1X, price: 795, interval: 'month', box_limit: 1, display_order: 1, features: [{'name' => 'Root Access', 'live' => true}, {'name' => 'Boxes Never Shutdown', 'live' => true}, {'name' => 'Box Snapshots', 'live' => true }, {'name' => 'Custom Domains', 'live' => true}]
plan_2x = maybe_create BoxhostPlan, name: DedicatedBoxhost::TYPES::TYPE_2X, price: 1495, interval: 'month', box_limit: 3, display_order: 2, features: [{'name' => 'Root Access', 'live' => true}, {'name' => 'Boxes Never Shutdown', 'live' => true}, {'name' => 'Box Snapshots', 'live' => true }, {'name' => 'Custom Domains', 'live' => true}]
plan_4x = maybe_create BoxhostPlan, name: DedicatedBoxhost::TYPES::TYPE_4X, price: 2995, interval: 'month', box_limit: 5, display_order: 3, features: [{'name' => 'Root Access', 'live' => true}, {'name' => 'Boxes Never Shutdown', 'live' => true}, {'name' => 'Box Snapshots', 'live' => true }, {'name' => 'Custom Domains', 'live' => true}]
plan_8x = maybe_create BoxhostPlan, name: DedicatedBoxhost::TYPES::TYPE_8X, price: 5995, interval: 'month', box_limit: 10, display_order: 4, features: [{'name' => 'Root Access', 'live' => true}, {'name' => 'Boxes Never Shutdown', 'live' => true}, {'name' => 'Box Snapshots', 'live' => true }, {'name' => 'Custom Domains', 'live' => true}]
plan_16x = maybe_create BoxhostPlan, name: DedicatedBoxhost::TYPES::TYPE_16X, price: 11995, interval: 'month', box_limit: 20, display_order: 5, features: [{'name' => 'Root Access', 'live' => true}, {'name' => 'Boxes Never Shutdown', 'live' => true}, {'name' => 'Box Snapshots', 'live' => true }, {'name' => 'Custom Domains', 'live' => true}]
plan_32x = maybe_create BoxhostPlan, name: DedicatedBoxhost::TYPES::TYPE_32X, price: 23995, interval: 'month', box_limit: 50, display_order: 6, features: [{'name' => 'Root Access', 'live' => true}, {'name' => 'Boxes Never Shutdown', 'live' => true}, {'name' => 'Box Snapshots', 'live' => true }, {'name' => 'Custom Domains', 'live' => true}]

digitalocean_plan_to_size = {
  plan_1x => Hostbuilder::DigitalOcean::Size::S_512MB,
  plan_2x => Hostbuilder::DigitalOcean::Size::S_1GB,
  plan_4x => Hostbuilder::DigitalOcean::Size::S_2GB,
  plan_8x => Hostbuilder::DigitalOcean::Size::S_4GB,
  plan_16x => Hostbuilder::DigitalOcean::Size::S_8GB,
  plan_32x => Hostbuilder::DigitalOcean::Size::S_16GB,
}

region_to_host_region_and_image = {
  us_west => [Hostbuilder::DigitalOcean::Region::SFO1, 3240036],
  us_east => [Hostbuilder::DigitalOcean::Region::NYC2, 3240036],
  eu_west => [Hostbuilder::DigitalOcean::Region::AMS2, 3240036],
  south_america => [Hostbuilder::DigitalOcean::Region::NYC2, 3240036],
  ap_northeast => [Hostbuilder::DigitalOcean::Region::SGP1, 4185676],
  ap_southeast => [Hostbuilder::DigitalOcean::Region::SGP1, 4185676],
  oceania => [Hostbuilder::DigitalOcean::Region::SGP1, 4185676],
}

# also created in a migration; this ensures either sequence (seed->migrate, migrate->seed) works
Box.all.each do |box|
  next if FreeBoxhost.find_by_name(box.host) || box.host.nil?
  new_host = FreeBoxhost.new(name: box.host)
  new_host.region_id = box.region_id
  new_host.save!
end

digitalocean_plan_to_size.each do |plan, size_id|
  region_to_host_region_and_image.each do |region, host_region_and_image|
    host_region_id, image_id = host_region_and_image
    maybe_create BoxhostProviderTemplate, provider: 'digital_ocean', name: "do-#{region.name}-#{host_region_id}", boxhost_plan_id: plan.id, region_id: region.id, config: { image_id: image_id, host_region_id: host_region_id, size_id: size_id }
  end
end

[
  { key: Box::N2O_MIN_MEMORY_MB,  value: 384   },
  { key: Box::N2O_MAX_MEMORY_MB,  value: 2048  },
  { key: Box::N2O_MIN_STORAGE_MB, value: 1000 },
  { key: Box::N2O_MAX_STORAGE_MB, value: 10000 },
  { key: N2oAllocation::N2O_250MB_STORAGE, value: 5 },
  { key: N2oAllocation::N2O_128MB_MEMORY,  value: 40 },
  { key: N2oFill::N2O_SIGN_UP_BONUS, value: 155 },
  { key: N2oFill::N2O_SIGN_UP_BONUS_EXTRA, value: 300 },
  { key: N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS, value: 10 },
  { key: N2oFill::N2O_INVITING_OUTSIDE_LIMITS_BONUS, value: 1 },
  { key: N2oFill::N2O_INVITED_SIGNUP_BONUS, value: 10 },
  { key: N2oFill::N2O_OAUTH_ACTION_BONUS, value: 5 },
  { key: N2oFill::N2O_INSTALL_CHROME_APP_BONUS, value: 10 },
  { key: N2oFill::N2O_TWITTER_FOLLOW_BONUS, value: 5 },
  { key: N2oFill::N2O_TWEET_SENT_BONUS, value: 5 },
  { key: N2oFill::N2O_BUSINESS_SURVEY_BONUS, value: 15 },
  { key: N2oFill::N2O_USER_SURVEY_1_BONUS, value: 25 },
  { key: AIO::N2O_PRICE_CENTS, value: 7 },
  { key: Invite::INVITE_MAX_REWARDABLE, value: 110 }
].each do |kv|
  unless KeyValue[kv[:key]].present?
    KeyValue.create key: kv[:key], value: kv[:value]
  end
end
