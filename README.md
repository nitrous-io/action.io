# Nitrous.IO

### Fetch submodules

`git submodule update --init`

### Bundle Install

`bundle install`

### Setup Environment Variables

`cp .env-example .env`

### Setup database

`export $(cat .env) && bundle exec rake db:setup db:migrate db:test:prepare`

### Populate Seed Data

`export $(cat .env) && bundle exec rake db:seed`

### Run Zeus (makes dev server, tests run faster)

`script/zeus`

### Run Rails/Thin

`script/server`

### Run Rainbow (needed for the console + file-browser API)

`cd ~/workspace/rainbow && ./script/server`

### Run Coach (HTTP interface for box provisioning)

`cd ~/workspace/coach && ./script/server`

### Run Boxer (Node.JS Server for box provisioning)

`cd ~/workspace/boxer && ./script/server`

### SSH Tunnels

Make sure you have SSH tunnels set up to port 5000 (the Rails app), port
5001 (Rainbow)

### Setting up some variables in the database

You need to setup the `box_server_uri` and `coach_uri`
attributes for the Region. Pick `ap-southeast-1`, enable it and set
the variables correctly.

```ruby
region = Region.find_by_name('ap-southeast-1')
region.enabled = true
region.box_server_uri = 'https://www.n2odev.com:5001'
region.coach_uri = 'http://www.n2odev.com:5002'
region.save
```

### Trusting security certificates

We use the self-signed certificate at [dev/n2odev.com.crt](dev/n2odev.com.crt)
to serve requests with SSL. To avoid browser warnings about security risks
trusting this certificate, you can add it to your Keychain (Chrome, Safari) or
use your browser's own certificate handler (Firefox).

### Running specs

#### Rails

Make sure you run `script/zeus`. Then run `bundle exec zeus rspec spec`. We're
aiming for 100% coverage on the Rails side.

### Frontend

To run frontend specs and goto
`http://www.n2odev.com:5000/spec`


#### Deployment

Add the following lines to your `~/.git/config`

```
[remote "production"]
 url = git@heroku.com:action.git
 fetch = +refs/heads/*:refs/remotes/production/*
[remote "staging"]
 url = git@heroku.com:action-staging.git
 fetch = +refs/heads/*:refs/remotes/staging/*
```

