#action.io

### Fetch submodules

`git submodule update --init`

### Populate Seed Data

`rake db:seed`

### Setup Environment Variables

`cp .env-example .env`
`vim .env`

### Run Postgres

`script/postgres`

### Run Redis

`script/redis`

### Run Spork

`script/spork`

### Run Resque Worker

`script/worker`

### Run Rails/Thin

`script/server`

### Setup some data

This is taken from [bombay dev README](https://github.com/action-io/bombay/blob/master/ansible/servers/dev/README.md)

```
bundle install
export $(cat .env) &&  bundle exec rake db:migrate
export $(cat .env) &&  bundle exec rake db:seed
```

Next you have to change some variables using the rails console. Log into rails console and run the following.

``` ruby
i = Invite.new
i.email = 'foo@action.io'
i.save
i.activate!
r = Region.all
r = Region.find(5)
r.enabled = true
r.box_server_uri = 'https://dev.action.io:5001'
r.coach_uri = 'http://dev.action.io:5002'
r.save
```
