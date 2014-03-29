describe 'AIO.Snapshot', ->
  model = null

  beforeEach ->
    model = AIO.Snapshot.create()

  describe 'validations', ->
    context 'name', ->
      it 'validates name to not exist', ->
        model.set 'name', null
        model.validate()
        expect(model.get 'errors.name').to.exist

      it 'validates name to exist', ->
        model.set 'name', 'foo'
        model.validate()
        expect(model.get 'errors.name').not.to.exist

  describe 'box', ->
    box = null

    beforeEach ->
      box = AIO.Box.create(id: 42, name: 'box-1')
      AIO.Box.all().set 'content', Em.A([box])

    afterEach ->
      AIO.Box.all().set 'content', Em.A()

    it 'returns the box it belongs to', ->
      model.set 'box_id', 42
      expect(model.get 'box').to.eql(box)

    it 'returns null when snapshot does not belong to a box', ->
      model.set 'box_id', null
      expect(model.get 'box').not.to.exist
