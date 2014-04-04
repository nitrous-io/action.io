describe 'App.BoxesControlView', ->
  view = null

  beforeEach ->
    view = App.BoxesControlView.create()

  afterEach ->
    view.destroy()

  describe '#memoryCost', ->
    beforeEach ->
      sinon.stub(App, 'get').withArgs('n2o128mbMemory').returns(40)

    afterEach ->
      App.get.restore()

    it 'returns the N2O cost of memory', ->
      view.set 'memory', 128
      expect(view.get('memoryCost')).to.equal 40
      view.set 'memory', 256
      expect(view.get('memoryCost')).to.equal 80

  describe '#storageCost', ->
    beforeEach ->
      sinon.stub(App, 'get').withArgs('n2o250mbStorage').returns(20)

    afterEach ->
      App.get.restore()

    it 'returns the N2O cost of storage', ->
      view.set 'storage', 250
      expect(view.get('storageCost')).to.equal 20
      view.set 'storage', 1000
      expect(view.get('storageCost')).to.equal 80

  describe '#totalCost', ->
    it 'returns memoryCost plus storageCost', ->
      view.set 'memoryCost', 200
      view.set 'storageCost', 300
      expect(view.get 'totalCost').to.equal 500
      view.set 'memoryCost', 100
      view.set 'storageCost', 500
      expect(view.get 'totalCost').to.equal 600

  describe '#remainingN2O', ->
    it 'returns free n2o minus totalCost', ->
      view.set 'freeN2O', 1000
      view.set 'totalCost', 200
      expect(view.get 'remainingN2O').to.equal 800
      view.set 'totalCost', 400
      expect(view.get 'remainingN2O').to.equal 600

  describe 'on box template selection', ->
    controller = null

    beforeEach ->
      controller = App.BoxesNewController.create(content: App.Box.create())
      view = App.BoxesControlView.create(controller: controller)

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
