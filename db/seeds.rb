# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

if BoxTemplate.count == 0
  BoxTemplate.create name: 'ubuntu + rails',  description: 'Ubuntu 11.10 + Ruby 1.9.3 + Rails 3.2.3', image: 'rails'
  BoxTemplate.create name: 'ubuntu + nodejs', description: 'Ubuntu 11.10 + Node.js 0.6.14',           image: 'nodejs'
end

if Region.count == 0
  us_west_1      = Region.create name: 'us-west-1',      description: 'US West (N. California)',   ami: 'ami-11c59d54', keypair: 'FIXME'
  us_west_2      = Region.create name: 'us-west-2',      description: 'US West (Oregon)',          ami: 'ami-a8ec6098', keypair: 'FIXME'
  us_east_1      = Region.create name: 'us-east-1',      description: 'US East (Virginia)',        ami: 'ami-4dad7424', keypair: 'FIXME'
  eu_west_1      = Region.create name: 'eu-west-1',      description: 'EU West (Ireland)',         ami: 'ami-81c5fdf5', keypair: 'FIXME'
  ap_southeast_1 = Region.create name: 'ap-southeast-1', description: 'Asia Pacific (Singapore)',  ami: 'ami-8e6027dc', keypair: 'FIXME'
  ap_northeast_1 = Region.create name: 'ap-northeast-1', description: 'Asia Pacific (Tokyo)',      ami: 'ami-44328345', keypair: 'FIXME'
  sa_east_1      = Region.create name: 'sa-east-1',      description: 'South America (Sao Paulo)', ami: 'ami-30b56b2d', keypair: 'FIXME'

  if BoxHost.count == 0
    BoxHost.create region_id: us_west_1.id,      name: 'Ali',       host: 'ali.us-west-1.action.io'
    BoxHost.create region_id: us_west_2.id,      name: 'Frazier',   host: 'frazier.us-west-2.action.io'
    BoxHost.create region_id: us_east_1.id,      name: 'Tyson',     host: 'tyson.us-east-1.action.io'
    BoxHost.create region_id: eu_west_1.id,      name: 'Lennox',    host: 'lennox.eu-west-1.action.io'
    BoxHost.create region_id: ap_southeast_1.id, name: 'Foreman',   host: 'foreman.ap-southeast-1.action.io'
    BoxHost.create region_id: ap_northeast_1.id, name: 'Holyfield', host: 'holyfield.ap-northeast-1.action.io'
    BoxHost.create region_id: sa_east_1.id,      name: 'Rocky',     host: 'rocky.sa-east-1.action.io'
  end
end

