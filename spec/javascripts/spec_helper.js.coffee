#= require application
#= require ember-bootstrap
#= require_self
#= require app

mocha.setup
  ui: 'bdd'
  globals: ['jQuery*', '__ember*', 'stats', 'failures', 'runner', 'window',
    'alert', 'setTimeout', 'setInterval', 'clearTimeout', 'clearInterval', 'confirm']
  checkLeaks: true
  timeout: 500
window.expect = chai.expect
window.onload = ->
  mocha.run()

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

window.spec =
  getController: (name) ->
    App.__container__.lookup("controller:#{name}")

  getMainRouter: ->
    App.Router.router

  getCurrentRouteName: ->
    Em.get(App.Router.router, 'currentHandlerInfos.lastObject.name')

  getCurrentRouteState: ->
    Em.get(App.Router.router, 'state')

  getCurrentRoute: ->
    @getMainRouter().getHandler(@getCurrentRouteName())

setupFixtures = ->
  App.bootstrap {
    environment: "test"
    firebaseHost: 'nitrous-firebase.example.com'
  }, {
    currentUser:
      id: 2
      username: "testuser"
      email: "testuser@example.com"
      full_name: null
      intro_seen: true
      authentications: [
        { id: 1, user_id: 2, provider: "github", uid: "62707" }
      ]
    boxes: [
      {
        id: 46
        name: "box"
        host: "46.137.252.155"
        state: "running"
        box_template_id: 1
        owner_id: 1
        region_id: 5
        port: 10251
        box_server_uri: "https://www.n2odev.com:5001"
      }
    ]
    regions: [
      { id: 1, name: "ap-southeast-1", description: "Southeast Asia" }
      { id: 2, name: "us-west-1", description: "US West" }
      { id: 3, name: "us-east-1", description: "US East" }
    ]
    boxTemplates: [
      { id: 1, name: "Ruby on Rails", description: "Ruby/Rails", enabled: true, runtime: "rails" }
      { id: 2, name: "Node.js", description: "Node.js", enabled: true, runtime: "nodejs" }
      { id: 3, name: "Python/Django", description: "Python/Django", enabled: true, runtime: "django" }
      { id: 4, name: "Go", description: "Go", enabled: true, runtime: "go" }
    ]
  }

# fake firebase class
firebasePushId = 0

class window.Firebase
  constructor: (@url) ->
  auth: ->
  unauth: ->
  push: ->
    new Firebase "#{@url}/-#{firebasePushId++}"
  remove: ->
  on: ->
  once: ->
  off: ->
  startAt: -> this
  endAt: -> this
  limit: -> this
  ref: -> this
  set: ->
  onDisconnect: ->
  toString: ->
    @url

beforeEach ->
  window.server.restore()
  window.server = sinon.fakeServer.create()

afterEach ->
  Em.run.sync()

$ ->
  $('body').append($('<div id="app">').hide())
  App.Router.reopen
    location: 'none'

  setupFixtures()
