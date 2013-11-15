describe 'AIO.BoxesNewController', ->
  beforeEach -> @controller = AIO.get("router.boxesNewController")

  describe '#newRecord', ->
    it 'creates a new clean box with template id', ->
      Em.run => @controller.newRecord()
      box = @controller.get('content')
      expect(box.get("boxTemplate.name")).to.equal "Ruby on Rails"

    it 'calls preselectRegion', ->
      sinon.spy(@controller, 'preselectRegion')
      Em.run => @controller.newRecord()
      expect(@controller.preselectRegion).to.have.been.called

  describe '#preselectRegion', ->
    box = null

    context 'when the box already has a region_id set', ->
      beforeEach ->
        box = {
          get: ->
          set: ->
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
        expect(box.set).to.not.have.been.called

    context 'when the controller already has the closestRegionId property set', ->
      beforeEach ->
        box = {
          get: ->
          set: ->
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
        }
        sinon.stub(box, 'get').withArgs('region_id').returns(null)
        @controller.set 'content', box
        @controller.set 'closestRegionId', null
        sinon.spy(AIO.Region, 'closestRegion')

      afterEach ->
        box.get.restore()
        AIO.Region.closestRegion.restore()

      it 'calls AIO.Region.closestRegion', ->
        Em.run => @controller.preselectRegion()
        expect(AIO.Region.closestRegion).to.have.been.called
