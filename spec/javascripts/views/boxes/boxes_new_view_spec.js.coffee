describe 'AIO.BoxesNewView', ->
  view = null

  beforeEach ->
    view = AIO.BoxesNewView.create()

  afterEach ->
    view.destroy()

  describe '#memoryCost', ->
    beforeEach ->
      sinon.stub(AIO, 'get').withArgs('n2o128mbMemory').returns(40)

    afterEach ->
      AIO.get.restore()

    it 'returns the N2O cost of memory', ->
      view.set 'memory', 128
      expect(view.get('memoryCost')).to.equal 40
      view.set 'memory', 256
      expect(view.get('memoryCost')).to.equal 80

  describe '#storageCost', ->
    beforeEach ->
      sinon.stub(AIO, 'get').withArgs('n2o250mbStorage').returns(20)

    afterEach ->
      AIO.get.restore()

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

