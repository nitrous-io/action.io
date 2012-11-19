root = exports ? this

# Indent by printing double space prior to message. Number of spaces depends on `level`
indent = (message, level) ->
  indentLevel = if level > 0 then ( "  " for i in [0..level] ).join("") else ""
  indentLevel + message

# log with indentation
log = (message, level=0) -> console.log indent(message, level)

timeInMs = (duration) -> ( duration / 1000 ).toFixed 5

# get a reference to old HTML reporter
HTMLReporter = root.mocha.reporters.HTML

# New reporter that behave like HTML reporter, but also print log to console
root.mocha.reporters.HTMLWithConsole = (runner, root) ->
  reporter = HTMLReporter(runner, root)
  host = window.location.host
  failed = false
  start = 0
  errors = []

  runner.on 'start', ->
    start = new Date

  runner.on 'end', (suite) ->
    log "#"
    errors.forEach (test) ->
      stack = test.err.stack || test.err.toString()
      log test.title
      log test.err.message, 1
      log stack, 1

    log "Duration: #{timeInMs(new Date - start)} ms"
    # special message to stop phantomjs from running forever !!
    msg = if errors.length > 0 then "Finished with failures" else "Finished without failures"
    log msg

  runner.on 'pass', (test, err) -> log "."
  runner.on 'pending', (test) -> log "P"
  runner.on 'fail', (test) -> errors.push(test) and log "F"
