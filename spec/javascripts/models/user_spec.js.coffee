describe "AIO.User", ->
  user = null
  beforeEach ->
    user = AIO.User.create()

  describe "#isGithubAuthenticated", ->
    it 'is true if the user has authenticated with github', ->
      user.set "authentications", [{id: 1, provider: "github"}]
      expect(user.get("isGithubAuthenticated")).to.be.true

    it 'is false if the user hasnt authenticated with github', ->
      user.set "authentications", []
      expect(user.get("isGithubAuthenticated")).to.be.false

  describe "#isAbleToInvite", ->
    it 'is true if the user has available invites', ->
      user.set "available_invites", 9
      expect(user.get("isAbleToInvite")).to.be.true

    it 'is false if the user doesnt have available invites', ->
      user.set "available_invites", 0
      expect(user.get("isAbleToInvite")).to.be.false

  describe '#free_n2o', ->
    it 'returns max_n2o - used_n2o', ->
      user.set 'max_n2o', 300
      user.set 'used_n2o', 200
      expect(user.get 'free_n2o').to.equal 100

  describe '#fetchN2O', ->
    beforeEach ->
      server.respondWith 'GET', '/n2o', [
        200
        { 'Content-Type': 'application/json; charset=utf-8' }
        '{ "n2o": { "max": 300, "used": 200 } }'
      ]

    it 'fetches n2o', ->
      expect(user.get 'max_n2o').to.equal 0
      expect(user.get 'used_n2o').to.equal 0
      expect(user.get 'free_n2o').to.equal 0
      user.fetchN2O()
      server.respond()
      expect(user.get 'max_n2o').to.equal 300
      expect(user.get 'used_n2o').to.equal 200
      expect(user.get 'free_n2o').to.equal 100
