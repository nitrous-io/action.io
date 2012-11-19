fs = require 'fs'

ANSI =
  color_map:
    "yellow" : `'\033[0;33m'`
    "green" : `'\033[0;32m'`
    "red" : `'\033[0;31m'`
  colorize_text: (text, color) ->
    color_code = @color_map[color]
    color_code + text + `"\033[0m"`

logToStdout = (text, color) ->
  text = ANSI.colorize_text(text, color) if color
  fs.write "/dev/stdout", text, "w"

# Color printing only result symbol
log = (msg) ->
  switch msg
    when "." then logToStdout(msg, "green")
    when "F" then logToStdout(msg, "red")
    when "P" then logToStdout(msg, "yellow")
    else console.log msg

if phantom.args.length == 0
  console.log "Need a url as the argument"
  phantom.exit 1

address = phantom.args
page = require('webpage').create()

# Don't supress console output
page.onConsoleMessage = (msg) ->
  log msg
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
