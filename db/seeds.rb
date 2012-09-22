# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

if BoxTemplate.count == 0
  BoxTemplate.create name: 'ubuntu + rails',  description: 'Ubuntu 11.10 + Ruby 1.9.3 + Rails 3.2.3', image: 'rails'
  BoxTemplate.create name: 'ubuntu + nodejs', description: 'Ubuntu 11.10 + Node.js 0.6.14',           image: 'nodejs'
end

if Region.count == 0
  us_west_1      = Region.create name: 'us-west-1',  description: 'us west (n. california)',        coach_uri: 'https://coach-usw-1.action.io',   box_server_uri: 'https://dominus-usw-1.action.io'
  us_west_2      = Region.create name: 'us-west-2',  description: 'us west (oregon)',               coach_uri: 'https://coach-usw-2.action.io',   box_server_uri: 'https://dominus-usw-2.action.io'
  us_east_1      = Region.create name: 'us-east-1',  description: 'us east (virginia)',             coach_uri: 'https://coach-use-1.action.io',   box_server_uri: 'https://dominus-use-1.action.io'
  eu_west_1      = Region.create name: 'eu-west-1',  description: 'eu west (ireland)',              coach_uri: 'https://coach-euw-1.action.io',   box_server_uri: 'https://dominus-euw-1.action.io'
  ap_southeast_1 = Region.create name: 'ap-southeast-1', description: 'asia pacific (singapore)',   coach_uri: 'https://coach-apse-1.action.io',  box_server_uri: 'https://dominus-apse-1.action.io'
  ap_northeast_1 = Region.create name: 'ap-northeast-1', description: 'asia pacific (tokyo)',       coach_uri: 'https://coach-apne-1.action.io',  box_server_uri: 'https://dominus-apne-1.action.io'
  sa_east_1      = Region.create name: 'sa-east-1',  description: 'south america (sao paulo)',      coach_uri: 'https://coach-sae-1.action.io',   box_server_uri: 'https://dominus-sae-1.action.io'
end

