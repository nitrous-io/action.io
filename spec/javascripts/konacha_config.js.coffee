#= require console_reporter
#= require_self

Konacha.mochaOptions.ui = 'bdd'
Konacha.mochaOptions.reporter = mocha.reporters.HTMLWithConsole
Konacha.mochaOptions.globals = ['jQuery*', '__ember*']
Konacha.mochaOptions.ignoreLeaks = false
Konacha.mochaOptions.timeout = 500
