describe 'App.BoxesControlWithNameGenerationView', ->
  view = null

  beforeEach ->
    view = App.BoxesControlWithNameGenerationView.create()

  afterEach ->
    view.destroy()

  it 'is a subclass of BoxesControlView', ->
    expect(view).to.be.instanceOf App.BoxesControlView

  describe 'on box template selection', ->
    controller = null

    beforeEach ->
      controller = App.BoxesNewController.create(content: App.Box.create())
      view.set 'controller', controller

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
