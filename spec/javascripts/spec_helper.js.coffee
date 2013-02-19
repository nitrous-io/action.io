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

setupFixtures = ->
  AIO.bootstrap
    environment: "test"
    pusherKey: undefined
    currentUser:
      user:
        id: 1,
        username: "admin",
        email: "admin@admin.com",
        full_name: null,
        available_invites: 2,
        authentications: [
          { id: 1, user_id: 1, provider: "github", uid: "62707" }
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
        box_server_uri: "https://dev.action.io:5001"
      }
    ]
    regions: [
      { id: 5, name: "ap-southeast-1", description: "Southeast Asia (Singapore)" }
    ]
    box_templates: [
      { id: 1, name: "Ruby on Rails", description: "Ruby/Rails", enabled: true, runtime: "rails" }
      { id: 2, name: "Node.js", description: "Node.js", enabled: true, runtime: "nodejs" }
      { id: 3, name: "Python/Django", description: "Python/Django", enabled: true, runtime: "django" }
      { id: 4, name: "Go", description: "Go", enabled: true, runtime: "go" }
    ]

beforeEach ->
  window.server.restore()
  window.server = sinon.fakeServer.create()
  Em.run -> setupFixtures()

afterEach ->
  #Em.run -> AIO.reset()

$ ->
  $('body').append($('<div id="app">').hide())
  #Ember.testing = true
  AIO.Router.reopen
    location: 'none'
  Em.run -> AIO.initialize()
