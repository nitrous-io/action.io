# Monkey-patched HTML reporter to add console.log capabilities to phantomjs too
root = exports ? this

host = "http://localhost:3500"

ANSI =
  color_map:
    "yellow" : `'\033[0;33m'`
    "green" : `'\033[0;32m'`
    "red" : `'\033[0;31m'`
  colorize_text: (text, color) ->
    color_code = @color_map[color]
    color_code + text + `"\033[0m"`

log = (message, color) ->
  text = if color then ANSI.colorize_text(message, color) else message
  console.log text

HTMLReporter = root.mocha.reporters.HTML

root.mocha.reporters.HTMLWithConsole = (runner, root) ->
  reporter = HTMLReporter(runner, root)

  runner.on 'suite', (suite) ->
    suite.failed = false
    if !suite.root
      url = "#{host}?grep=#{encodeURIComponent(suite.fullTitle())}"
      log url, 'yellow'

  runner.on 'suite end', (suite) ->
    if suite.root
      if suite.failed
        log "Finished with failures"
      else
        log "Finished without failures"
    else
      suite.parent.failed = suite.failed

  runner.on 'test end', (test, err) ->
    if test.state == 'passed'
      log test.title, 'green'
    else if test.pending
      log test.title
    else
      test.parent.failed = true
      stack = test.err.stack || test.err.toString()
      log test.title, 'red'
      log stack, 'red'
