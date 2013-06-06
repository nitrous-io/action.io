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

  describe '#isActivated', ->
    it 'is true if the user is activated', ->
      user.set "activated", true
      expect(user.get("isActivated")).to.be.true
      user.set "activated", false
      expect(user.get("isActivated")).to.be.false

  describe '#canCreateBox', ->
    it 'is true if user is allowed to create a box',->
      user.set "actions", { create_box: true }
      expect(user.get("canCreateBox")).to.be.true

    it 'is false if user isnt allowed to create a box',->
      user.set "actions", { create_box: false }
      expect(user.get("canCreateBox")).to.be.false

  describe '#shouldShowIntro', ->
    it 'is true if the intro is not completed', ->
      user.set "intro_completed", false
      expect(user.get("shouldShowIntro")).to.be.true
      user.set "intro_completed", true
      expect(user.get("shouldShowIntro")).to.be.false

  describe '#hideTour', ->
    beforeEach ->
      sinon.spy(jQuery, "ajax")

    afterEach ->
      jQuery.ajax.restore()

    it 'should POST to /app/end_intro', ->
      user.endIntro()
      expect(jQuery.ajax.firstCall.args[0].url).to.eql '/app/end_intro'
