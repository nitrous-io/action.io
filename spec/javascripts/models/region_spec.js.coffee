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

