# action.io

### Fetch submodules

`git submodule update --init`

### Bundle Install

`bundle install`

### Setup Environment Variables

`cp .env-example .env`

### Setup database

`export $(cat .env) && bundle exec rake db:migrate db:test:prepare`

### Populate Seed Data

`export $(cat .env) && bundle exec rake db:seed`

### Run Spork (for faster tests)

`script/spork`

### Run Rails/Thin

`script/server`

### Run Rainbow (needed for the console + file-browser API)

``` cd ~/workspace/rainbow && ./script/server```

### Run Coach (HTTP interface for box provisioning)

``` cd ~/workspace/coach && ./script/server ```

### Run Boxer (Node.JS Server for box provisioning)

``` cd ~/workspace/boxer && ./script/server ```

### SSH Tunnels

Make sure you have SSH tunnels set up to port 5000 (the Rails app), port
5001 (Rainbow) and 4000 (for Konacha frontend tests)

### Setting up some variables in the database

You need to setup the ```box_server_uri``` and ```coach_uri```
attributes for the Region. Pick ```ap-southeast-1```, enable it and set
the variables correctly.


``` ruby
region = Region.find_by_name('ap-southeast-1')
regin.enabled = true
region.box_server_uri = 'https://dev.action.io:5001'
region.coach_uri = 'http://dev.action.io:5002'
region.save
```

### Setting up a user

``` ruby
invite = Invite.new
invite.email = 'foo@action.io'
invite.save
invite.activate!
```

Get the invite code ```invite.reload.invite_code```, and sign up at
```https://dev.action.io:5000/users/sign_up``` and use the same email
address and the invite code as your invite.

### Running specs

#### Rails

Make sure you run ```script/spork``` for great justice. Then run ```
rspec spec```. We're aiming for 100% coverage on the Rails side.

### Frontend

Run ```script/konacha``` to run frontend specs and goto
http://dev.action.io:4000




