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

  describe 'canCreateBox', ->
    it 'is true if user is allowed to create a box',->
      user.set "actions", { create_box: true }
      expect(user.get("canCreateBox")).to.be.true

    it 'is false if user isnt allowed to create a box',->
      user.set "actions", { create_box: false }
      expect(user.get("canCreateBox")).to.be.false

  describe 'hideTour', ->
    beforeEach ->
      sinon.spy(jQuery, "ajax")

    afterEach ->
      jQuery.ajax.restore()

    context 'boxes tour', ->
      it 'should POST to /app/hide_boxes_tour', ->
        user.hideTour 'boxes'
        expect(jQuery.ajax.firstCall.args[0].url).to.eql '/app/hide_boxes_tour'

    context 'ide tour', ->
      it 'should POST to /app/hide_ide_tour', ->
        user.hideTour 'ide'
        expect(jQuery.ajax.firstCall.args[0].url).to.eql '/app/hide_ide_tour'

  describe 'shouldHideTour', ->
    context 'boxes tour', ->
      it 'is true if hide_boxes_tour is true',->
        user.set "hide_boxes_tour", true
        expect(user.shouldHideTour('boxes')).to.be.true

      it 'is false if hide_boxes_tour is false',->
        user.set "hide_boxes_tour", false
        expect(user.shouldHideTour('boxes')).to.be.false

    context 'ide tour', ->
      it 'is true if hide_ide_tour is true',->
        user.set "hide_ide_tour", true
        expect(user.shouldHideTour('ide')).to.be.true

      it 'is false if hide_ide_tour is false',->
        user.set "hide_ide_tour", false
        expect(user.shouldHideTour('ide')).to.be.false

    context 'some other tour', ->
      it 'always returns true',->
        expect(user.shouldHideTour('some')).to.be.true
