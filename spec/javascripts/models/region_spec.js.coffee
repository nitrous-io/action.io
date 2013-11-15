describe 'AIO.Region', ->
  model = null

  beforeEach ->
    model = AIO.Region.create()

  describe 'enabled', ->
    context 'when state is up', ->
      it 'returns true', ->
        model.set 'state', 'up'
        expect(model.get 'enabled').to.eql(true)

    context 'when state is going_down', ->
      it 'returns true', ->
        model.set 'state', 'going_down'
        expect(model.get 'enabled').to.eql(true)

    context 'when state is down', ->
      it 'returns false', ->
        model.set 'state', 'down'
        expect(model.get 'enabled').to.eql(false)

  describe 'going_down', ->
    context 'when state is up', ->
      it 'returns false', ->
        model.set 'state', 'up'
        expect(model.get 'goingDown').to.eql(false)

    context 'when state is going_down', ->
      it 'returns true', ->
        model.set 'state', 'going_down'
        expect(model.get 'goingDown').to.eql(true)

  describe '.closestRegion', ->

    context 'when the response is successful', ->
      stubClosestRegion = null

      beforeEach ->
        window.server.respondWith 'GET', '/regions/closest',
                             [ 200, { 'Content-Type': 'application/json' },
                             '{ "region": { "id": "123" } }' ]
        stubClosestRegion = sinon.stub()
        sinon.stub(AIO.Region, 'create').returns(stubClosestRegion)

      afterEach ->
        AIO.Region.create.restore()

      it 'responds with a region', ->
        callback = sinon.spy()
        AIO.Region.closestRegion(callback)
        window.server.respond()

        expect(callback).to.have.been.calledWith(null, stubClosestRegion)

    context 'when the request to get the closest region fails', ->
      beforeEach ->
        window.server.respondWith 'GET', '/regions/closest',
                             [ 404, { 'Content-Type': 'application/json' },
                             '{ "error": "unknown closest region" }' ]

      it 'returns an error', ->
        callback = sinon.spy()
        AIO.Region.closestRegion(callback)
        window.server.respond()

        expect(callback).to.have.been.calledWith('unknown closest region')
