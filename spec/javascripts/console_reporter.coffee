root = exports ? this

# take care of pretty-printing colorful log message
ANSI =
  color_map:
    "yellow" : `'\033[0;33m'`
    "green" : `'\033[0;32m'`
    "red" : `'\033[0;31m'`
  colorize_text: (text, color) ->
    color_code = @color_map[color]
    color_code + text + `"\033[0m"`

# Print log message with color if possible
# Example:
#   > log "awesome function", "green"
#   > log "bad function", "red"
#   > log "not so hot function", "yellow"
log = (message, color) ->
  text = if color then ANSI.colorize_text(message, color) else message
  console.log text

# Indent by printing double space prior to message. Number of spaces depends on `level`
indent = (message, level) -> ( "  " for i in [0..level] ).join("") + message

# log with indentation
indentLog = (message, level=0, color) -> log indent(message, level), color

timeInMs = (duration) -> ( duration / 1000 ).toFixed 5

# format test title with duration
titleWithDuration = (test) -> "#{test.title} (#{timeInMs(test.duration)} ms)"

# get a reference to old HTML reporter
HTMLReporter = root.mocha.reporters.HTML

# New reporter that behave like HTML reporter, but also print log to console
root.mocha.reporters.HTMLWithConsole = (runner, root) ->
  reporter = HTMLReporter(runner, root)
  host = window.location.host
  failed = false
  start = 0

  runner.on 'start', ->
    start = new Date

  runner.on 'suite', (suite) ->
    unless suite.root
      suite.indentLevel = if suite.parent.root then 0 else suite.parent.indentLevel + 1
      url = "#{host}?grep=#{suite.fullTitle()}"
      indentLog url, suite.indentLevel, 'yellow'

  runner.on 'suite end', (suite) ->
    if suite.root
      log "Duration: #{timeInMs(new Date - start)} ms"
      msg = if failed then "Finished with failures" else "Finished without failures"
      log msg

  runner.on 'failed', (test, err) ->
    failed = true
    stack = test.err.stack || test.err.toString()
    indentLog titleWithDuration(test), indentLevel, 'red'
    indentLog stack, indentLevel, 'red'

  runner.on 'test end', (test, err) ->
    indentLevel = test.parent.indentLevel + 1
    if test.state == 'passed'
      indentLog titleWithDuration(test), indentLevel, 'green'
    else if test.pending
      indentLog titleWithDuration(test), indentLevel
