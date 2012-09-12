#= require application
#= require sinon-1.4.2
#= require sinon-chai
#= require_self
#= require aio

chai.Assertion.includeStack = true

# aliases
window.beforeAll = before
window.afterAll = after
window.context = describe
window.xcontext = xdescribe
window.specify = it
window.xspecify = xit
window.its = it
window.xits = xit
window.server = sinon.fakeServer.create()

beforeEach ->
  window.server.restore()
  window.server = sinon.fakeServer.create()

$ ->
  $('body').append($('<div id="app">').hide())
  AIO.Router.reopen
    location: 'none'
  AIO.initialize()

