# How to get Vline integration to work on Dev

* Use the settings in .env-vline
* Start the thin server without SSL support (`bundle exec thin start -p $PORT -e development`)
* Register for an account in forwardhq.com and install the gem `forward`
* Run `forward $PORT`
* You might need to login to vline account (the settings in .env-vline is for the account lakshan@nitrous.io - I will email you the password)
