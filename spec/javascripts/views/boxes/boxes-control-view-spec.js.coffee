describe 'App.BoxesControlView', ->
  view = null

  beforeEach ->
    view = App.BoxesControlView.create()

  afterEach ->
    view.destroy()

  describe '#memoryCost', ->
    beforeEach ->
      App.set 'config.n2o128mbMemory', 40

    afterEach ->
      App.set 'config.n2o128mbMemory', null

    it 'returns the N2O cost of memory', ->
      view.set 'memory', 128
      expect(view.get('memoryCost')).to.equal 40
      view.set 'memory', 256
      expect(view.get('memoryCost')).to.equal 80

  describe '#storageCost', ->
    beforeEach ->
      App.set 'config.n2o250mbStorage', 20

    afterEach ->
      App.set 'config.n2o250mbStorage', null

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
