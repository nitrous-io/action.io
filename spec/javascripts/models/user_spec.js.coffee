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

  describe "#isGoogleAuthenticated", ->
    it 'is true if the user has authenticated with google', ->
      user.set "authentications", [{id: 1, provider: "google"}]
      expect(user.get("isGoogleAuthenticated")).to.be.true

    it 'is false if the user hasnt authenticated with google', ->
      user.set "authentications", []
      expect(user.get("isGoogleAuthenticated")).to.be.false

  describe "#isLinkedinAuthenticated", ->
    it 'is true if the user has authenticated with linkedin', ->
      user.set "authentications", [{id: 1, provider: "linkedin"}]
      expect(user.get("isLinkedinAuthenticated")).to.be.true

    it 'is false if the user hasnt authenticated with linkedin', ->
      user.set "authentications", []
      expect(user.get("isLinkedinAuthenticated")).to.be.false

  describe "#isConfirmed", ->
    it 'is true if the cofirmed at is set', ->
      user.set "confirmed_at", "2013-06-18T04:23:29Z"
      expect(user.get("isConfirmed")).to.be.true

    it 'is false if the cofirmed at is not set', ->
      user.set "confirmed_at", null
      expect(user.get("isConfirmed")).to.be.false

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

  describe '#referralLinkFullURL', ->
    beforeEach ->
      user.set 'referral_link', '/join/foobar'

    it 'adds protocol and host name', ->
      expect(user.get 'referralLinkFullURL').to.equal "#{location.protocol}//#{location.host}/join/foobar"

  describe '#gravatarUrl', ->
    beforeEach ->
      user.set 'gravatar_hash', '123456789'

    it 'returns the full gravatar image url', ->
      expect(user.get 'gravatarUrl').to.equal "http://www.gravatar.com/avatar/#{user.get('gravatar_hash')}"

  describe '#updateInfo', ->
    beforeEach ->
      user.set 'id', 123

    afterEach ->
      user.set 'id', null

    it 'saving flag is set to true', ->
      user.updateInfo()
      expect(user.get 'saving').to.be.true

    context 'when response is successful', ->
      beforeEach ->
        window.server.respondWith "PUT", "/users",
                             [ 200, { "Content-Type": "application/json" },
                             '{ "user": { "id": 123, "email": "test@nitrous.io" } }' ]
        user.updateInfo()
        window.server.respond()

      it 'saving flag is set to false', ->
        expect(user.get 'saving').to.be.false

      it 'deserializes the JSON response', ->
        expect(user.get 'email').to.eql "test@nitrous.io"

    context 'when response is a 422 error', ->
      beforeEach ->
        window.server.respondWith "PUT", "/users",
                             [ 422, { "Content-Type": "application/json" },
                             '{ "errors": { "base": ["Some error occurred."] } }' ]
        user.updateInfo()
        window.server.respond()

      it 'sets the error', ->
        expect(user.get 'errors').to.eql { base: [ "Some error occurred." ] }

      it 'saving flag is set to false', ->
        expect(user.get 'saving').to.be.false
