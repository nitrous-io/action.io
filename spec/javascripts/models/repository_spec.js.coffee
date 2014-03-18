describe 'AIO.Repository', ->
  model = null

  beforeEach ->
    model = AIO.Repository.create()

  describe 'box', ->
    box = Em.Object.create(id: 42, name: 'box-1')

    beforeEach ->
      sinon.stub AIO.get('router.boxesController'), 'findById'
      AIO.get('router.boxesController').findById.withArgs(42).returns box

    afterEach ->
      AIO.get('router.boxesController').findById.restore()

    it 'returns the box it belongs to', ->
      model.set 'box_id', 42
      expect(model.get 'box').to.eql(box)

    it 'returns null when repository does not belong to a box', ->
      model.set 'box_id', null
      expect(model.get 'box').not.to.exist
