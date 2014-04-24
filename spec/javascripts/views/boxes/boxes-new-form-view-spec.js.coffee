describe 'App.BoxesNewFormView', ->
  describedClass = App.BoxesNewFormView
  view = box = controller = null

  beforeEach ->
    box = App.Box.create(id: 123)
    controller = App.BoxesNewController.create(content: box)
    view = describedClass.create(controller: controller)

  afterEach ->
    view.destroy()

  it 'is a subclass of BoxesControlView', ->
    expect(view).to.be.instanceOf App.BoxesControlView

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

  describe 'on box template change', ->
    beforeEach ->
      box.set 'source_snapshot_id', 1

    context 'when a box template is selected', ->
      it 'unselects source snapshot', ->
        box.set 'box_template_id', 2
        expect(box.get 'box_template_id').to.equal 2
        expect(box.get 'source_snapshot_id').to.be.null

    context 'when the box template is unselected', ->
      it 'does nothing', ->
        box.set 'box_template_id', 2
        expect(box.get 'box_template_id').to.equal 2
        expect(box.get 'source_snapshot_id').to.be.null

  describe 'on source snapshot change', ->
    context 'when a source snapshot is selected', ->
      beforeEach ->
        box.set 'box_template_id', 2

      it 'unselectes box template', ->
        box.set 'source_snapshot_id', 1
        expect(box.get 'source_snapshot_id').to.equal 1
        expect(box.get 'box_template_id').to.be.null

    context 'when the source snapshot is unselected', ->
      beforeEach ->
        box.set 'source_snapshot_id', 1

      context 'when a box template is selected (resulting in the unselection of source snapshot)', ->
        beforeEach ->
          box.set 'box_template_id', 2

        it 'does nothing', ->
          expect(box.get 'source_snapshot_id').to.be.null
          expect(box.get 'box_template_id').to.equal 2

      context 'when the box template is not selected', ->
        beforeEach ->
          box.set 'source_snapshot_id', null

        it 'selects the first box template', ->
          expect(box.get 'source_snapshot_id').to.be.null
          expect(box.get 'box_template_id').to.equal 1
