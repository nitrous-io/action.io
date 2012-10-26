# coding: utf-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

if BoxTemplate.count == 0
  BoxTemplate.create name: 'ubuntu + rails',  description: 'Ubuntu 11.10 + Ruby 1.9.3 + Rails 3.2.3', image: 'rails'
  BoxTemplate.create name: 'ubuntu + nodejs', description: 'Ubuntu 11.10 + Node.js 0.6.14',           image: 'nodejs'
end

if Region.count == 0
  us_west_1      = Region.create name: 'us-west-1',      description: 'US West (N. California)',    coach_uri: 'https://coach-usw1.action.io',   box_server_uri: 'https://rainbow-usw1.action.io'
  us_west_2      = Region.create name: 'us-west-2',      description: 'US West (Oregon)',           coach_uri: 'https://coach-usw2.action.io',   box_server_uri: 'https://rainbow-usw2.action.io'
  us_east_1      = Region.create name: 'us-east-1',      description: 'US East (Virginia)',         coach_uri: 'https://coach-use1.action.io',   box_server_uri: 'https://rainbow-use1.action.io'
  eu_west_1      = Region.create name: 'eu-west-1',      description: 'Western Europe (Ireland)',   coach_uri: 'https://coach-euw1.action.io',   box_server_uri: 'https://rainbow-euw1.action.io'
  ap_southeast_1 = Region.create name: 'ap-southeast-1', description: 'Southeast Asia (Singapore)', coach_uri: 'https://coach-apse1.action.io',  box_server_uri: 'https://rainbow-apse1.action.io'
  ap_northeast_1 = Region.create name: 'ap-northeast-1', description: 'East Asia (Tokyo)',          coach_uri: 'https://coach-apne1.action.io',  box_server_uri: 'https://rainbow-apne1.action.io'
  sa_east_1      = Region.create name: 'sa-east-1',      description: 'South America (São Paulo)',  coach_uri: 'https://coach-sae1.action.io',   box_server_uri: 'https://rainbow-sae1.action.io'
end

