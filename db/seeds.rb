# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

if BoxTemplate.count == 0
  BoxTemplate.create name: 'ubuntu + rails',  description: 'Ubuntu 11.10 + Ruby 1.9.3 + Rails 3.2.3', image: 'rails'
  BoxTemplate.create name: 'ubuntu + nodejs', description: 'Ubuntu 11.10 + Node.js 0.6.14',           image: 'nodejs'
end
