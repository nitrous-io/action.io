#= require spec_helper

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
