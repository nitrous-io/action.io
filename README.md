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

