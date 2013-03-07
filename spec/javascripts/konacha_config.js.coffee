#= require console_reporter
#= require_self

Konacha.mochaOptions.ui = 'bdd'
# if running in the browser mode, we want phantomjs too
if Konacha.mochaOptions.reporter == mocha.reporters.HTML
  Konacha.mochaOptions.reporter = mocha.reporters.HTMLWithConsole
Konacha.mochaOptions.globals = ['jQuery*', '__ember*', 'stats', 'failures', 'runner', 'window', 'alert']
Konacha.mochaOptions.ignoreLeaks = false
Konacha.mochaOptions.timeout = 500
