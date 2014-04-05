describe 'App.BoxesNewView', ->
  view = controller = null

  beforeEach ->
    controller = App.BoxesNewController.create(content: App.Box.create())
    view = App.BoxesNewView.create(controller: controller)

  afterEach ->
    view.destroy()

  describe 'on insert', ->
    beforeEach ->
      sinon.stub view, 'preselectRegion'

    it 'calls preselectRegion', ->
      view.didInsertElement()
      expect(view.preselectRegion).to.have.been.called

  describe '#preselectRegion, and on closest region id change', ->
    box = null

    context 'when the closestRegionId is already found', ->
      afterEach ->
        App.set 'closestRegionId', null

      context 'when the controller already has a region_id set', ->
        beforeEach ->
          controller.set 'region_id', 8
          App.set 'closestRegionId', 123

        it 'does not alter region_id', ->
          expect(controller.get 'region_id').to.equal 8

      context "when the controller's region_id is not yet set", ->
        it 'sets the region_id to be the closestRegionId', ->
          App.set 'closestRegionId', 123
          expect(controller.get 'region_id').to.equal 123

    context 'when the box does not have a region_id and the closestRegionId is not yet found', ->
      beforeEach ->
        App.set 'closestRegionId', null
        sinon.stub App.Region, 'fetchClosestRegion'

      afterEach ->
        App.Region.fetchClosestRegion.restore()

      it 'calls App.Region.fetchClosestRegion', ->
        view.preselectRegion()
        expect(controller.get 'region_id').not.to.exist
        expect(App.Region.fetchClosestRegion).to.have.been.called

  describe 'on box template selection', ->
    beforeEach ->
      controller.set 'box_template_id', null
      controller.set 'source_snapshot_id', 123
      controller.set 'name', 'my-box'
      sinon.stub App.RandomBoxNameGenerator, 'generate', (extra) ->
        "random-#{extra}-box"

    afterEach ->
      App.RandomBoxNameGenerator.generate.restore()

    context 'if a box template is selected (box_template_id is set)', ->
      doAction = ->
        controller.set 'box_template_id', 1

      context "if box name isn't dirty (user customized) yet", ->
        beforeEach ->
          doAction()

        it 'unselects source snapshot', ->
          expect(controller.get 'source_snapshot_id').to.be.null

        it 'sets random box name', ->
          expect(controller.get 'name').to.equal 'random-rails-box'

      context 'if box name is dirty', ->
        beforeEach ->
          controller.set 'boxNameIsDirty', true
          doAction()

        it 'does not mess with it', ->
          expect(controller.get 'name').to.equal 'my-box'

    context 'if a box template is unselected', ->
      beforeEach ->
        controller.set 'box_template_id', null

      it 'does not do anything', ->
        expect(controller.get 'source_snapshot_id').to.equal 123
        expect(controller.get 'name').to.equal 'my-box'
