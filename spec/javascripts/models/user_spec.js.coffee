describe "AIO.User", ->
  user = null
  beforeEach ->
    user = AIO.User.createRecord()

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

