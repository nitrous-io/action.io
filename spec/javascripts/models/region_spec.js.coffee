describe 'AIO.Region', ->
  model = null

  beforeEach ->
    model = AIO.Region.create()

  describe 'enabled', ->
    context 'when state is up', ->
      it 'returns true', ->
        model.set 'state', 'up'
        expect(model.get 'enabled').to.be.true

    context 'when state is going_down', ->
      it 'returns true', ->
        model.set 'state', 'going_down'
        expect(model.get 'enabled').to.be.true

    context 'when state is down', ->
      it 'returns false', ->
        model.set 'state', 'down'
        expect(model.get 'enabled').to.be.false

  describe 'going_down', ->
    context 'when state is up', ->
      it 'returns false', ->
        model.set 'state', 'up'
        expect(model.get 'goingDown').to.be.false

    context 'when state is going_down', ->
      it 'returns true', ->
        model.set 'state', 'going_down'
        expect(model.get 'goingDown').to.be.true

  describe '.fetchClosestRegion', ->
    it 'does a GET request to /regions/fetch_closest', ->
      AIO.Region.fetchClosestRegion()
      lastRequest = server.requests[0]
      expect(lastRequest.method).to.equal 'GET'
      expect(lastRequest.url).to.equal '/regions/fetch_closest'
