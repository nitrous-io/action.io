describe 'AIO.BoxesNewController', ->
  beforeEach -> @controller = AIO.BoxesNewController.create()

  describe '#newRecord', ->
    it 'creates a new clean box with template id', ->
      Em.run => @controller.newRecord()
      box = @controller.get('content')
      expect(box.get('boxTemplate.name')).to.equal 'Ruby on Rails'

    it 'calls preselectRegion', ->
      sinon.spy(@controller, 'preselectRegion')
      Em.run => @controller.newRecord()
      expect(@controller.preselectRegion).to.have.been.called
      @controller.preselectRegion.restore()

    it 'calls handleIntent', ->
      sinon.spy(@controller, 'handleIntent')
      Em.run => @controller.newRecord()
      expect(@controller.handleIntent).to.have.been.called
      @controller.handleIntent.restore()

  describe '#preselectRegion', ->
    box = null

    context 'when the box already has a region_id set', ->
      beforeEach ->
        box = {
          get: ->
          set: ->
          randomName: -> 'foo'
        }
        sinon.stub(box, 'get').withArgs('region_id').returns(8)
        sinon.spy(box, 'set')
        @controller.set 'content', box

      afterEach ->
        box.get.restore()
        box.set.restore()

      it 'does not set the region_id of the box', ->
        Em.run => @controller.preselectRegion()
        expect(box.get).to.have.been.called
        expect(box.set).to.not.have.been.calledWith 'region_id'

    context 'when the controller already has the closestRegionId property set', ->
      beforeEach ->
        box = {
          get: ->
          set: ->
          randomName: -> 'foo'
        }
        sinon.stub(box, 'get').withArgs('region_id').returns(null)
        sinon.spy(box, 'set')
        @controller.set 'content', box
        @controller.set 'closestRegionId', 42

      afterEach ->
        box.get.restore()
        box.set.restore()

      it 'sets the region_id of the box to the closestRegionId', ->
        Em.run => @controller.preselectRegion()
        expect(box.set).to.have.been.calledWith 'region_id', 42

    context 'when the box does not have a region_id and the controller does not have a closestRegionId', ->
      beforeEach ->
        box = {
          get: ->
          set: ->
          randomName: -> 'foo'
        }
        sinon.stub(box, 'get').withArgs('region_id').returns(null)
        @controller.set 'content', box
        @controller.set 'closestRegionId', null
        sinon.spy(AIO.Region, 'fetchClosestRegion')

      afterEach ->
        box.get.restore()
        AIO.Region.fetchClosestRegion.restore()

      it 'calls AIO.Region.fetchClosestRegion', ->
        Em.run => @controller.preselectRegion()
        expect(AIO.Region.fetchClosestRegion).to.have.been.called

  describe '#closestRegionIdDidChange observer', ->
    beforeEach -> sinon.stub(@controller, 'preselectRegion')
    afterEach -> @controller.preselectRegion.restore()

    it 'calls preselectRegion when the closestRegionId changes', ->
      Em.run => @controller.set 'closestRegionId', 42
      expect(@controller.preselectRegion).to.have.been.called

  describe '#boxTemplateIdDidChange observer', ->
    box = null

    beforeEach ->
      box = AIO.Box.create()
      sinon.stub(box, 'randomName').returns('emma-watsons-treasure')
      sinon.spy(@controller, 'set')
      @controller.set 'content', box

    afterEach ->
      box.randomName.restore()
      @controller.set.restore()

    it 'sets the box name to a random name when its box_template_id changes', ->
      Em.run => @controller.set 'box_template_id', 9000
      expect(@controller.set).to.have.been.calledWith('name', 'emma-watsons-treasure')
      box = @controller.get('content')
      expect(box.get 'name').to.equal 'emma-watsons-treasure'

    it 'does not change the box name to a random name when it has been changed by the user', ->
      @controller.set 'name', 'hermione'
      @controller.set 'boxNameIsDirty', true
      Em.run => @controller.set 'box_template_id', 9000
      expect(box.get 'name').to.equal 'hermione'

    context 'when the random name is already in use by an existing box', ->
      boxes = null

      beforeEach ->
        boxes = []
        sinon.stub(AIO, 'get').withArgs('router.boxesController.content').returns(boxes)
        sinon.stub(_, 'find').withArgs(boxes).returns({ name: 'emma-watsons-treasure' })

      afterEach ->
        AIO.get.restore()
        _.find.restore()

      it "suffixes '-1' to the random name", ->
        Em.run => @controller.set 'box_template_id', 9000
        expect(@controller.set).to.have.been.calledWith('name', 'emma-watsons-treasure-1')
        box = @controller.get('content')
        expect(box.get 'name').to.equal 'emma-watsons-treasure-1'

  describe '#handleIntent', ->
    box = null

    beforeEach ->
      box = {
        get: ->
        set: ->
        randomName: -> 'foo'
      }
      sinon.spy(box, 'set')
      @controller.set 'content', box

    context 'when the current user has an intended clone repo URL', ->
      beforeEach ->
        user = {
          get: ->
        }
        sinon.stub(user, 'get').withArgs('intendedCloneRepoURL').returns('https://github.com/rails/rails.git')
        AIO.set 'currentUser', user

      afterEach ->
        box.set.restore()

      it 'sets the repository_clone_url to the intended clone repo URL', ->
        Em.run => @controller.handleIntent()
        expect(box.set).to.have.been.calledWith('repository_clone_url', 'https://github.com/rails/rails.git')

    context 'when the current user does not have an intended clone repo URL', ->
      beforeEach ->
        user = {
          get: ->
        }
        sinon.stub(user, 'get').withArgs('intendedCloneRepoURL').returns(null)
        AIO.set 'currentUser', user

      afterEach ->
        box.set.restore()

      it 'does not set the repository_clone_url', ->
        Em.run => @controller.handleIntent()
        expect(box.set).to.not.have.been.calledWith('repository_clone_url')
