if phantom.args.length == 0
  console.log "Need a url as the argument"
  phantom.exit 1

address = phantom.args
page = require('webpage').create()

# Don't supress console output
page.onConsoleMessage = (msg) ->
  console.log msg
  if msg == "Finished with failures"
    phantom.exit 1
  else if msg == "Finished without failures"
    phantom.exit 0


# Terminate when the reporter singals that testing is over.
# We cannot use a callback function for this (because page.evaluate is
# sandboxed),
page.open address, (status) ->
  if status != "success"
    errors.push status
