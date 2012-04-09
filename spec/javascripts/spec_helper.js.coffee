# alias beforeEach and afterEach
window.before = window.beforeEach
window.after = window.afterEach
window.specify = window.it
window.context = window.describe

# monkey patch jasmine-jquery so that cleanup is done in beforeEach instead of afterEach
afterEachFns = jasmine.getEnv().currentRunner_.after_
for item, i in afterEachFns
  if item.toString().match(/\.cleanUp\(\)/)
    afterEachFns.splice(i, 1)
    jasmine.getEnv().currentRunner_.before_.push ->
      jasmine.getFixtures().cleanUp()
      jasmine.JQuery.events.cleanUp()
      if $('#jasmine-fixtures').length == 0
        $('body').append($('<div id="jasmine-fixtures">'))
    break

beforeEach ->
  $.fx.off = true
  #Backbone.history.stop() if Backbone.history
  clearAjaxRequests()
  window.location.hash = '' if window.location.hash.length > 0

window.$findOne = ->
  $obj = $.apply(this, arguments)
  expect($obj.length).toEqual 1
  $obj

window.$find = ->
  $obj = $.apply(this, arguments)
  expect($obj.length).toBeGreaterThan 0
  $obj

