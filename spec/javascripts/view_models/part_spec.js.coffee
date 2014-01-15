describe 'AIO.Part', ->
  model = null

  beforeEach ->
    model = AIO.Part.create()

  describe 'humanized', ->
    beforeEach ->
      model.set 'name', 'ack'
      model.set 'description', 'Ack: A tool like grep, optimized for programmers'

    it 'returns the humanized name', ->
      expect(model.get 'humanized.name').to.eql 'Ack'

    it 'returns the humanized description', ->
      expect(model.get 'humanized.description').to.eql 'A tool like grep, optimized for programmers'

  describe 'running', ->
    context 'when the status is null', ->
      it 'return false', ->
        model.set 'status', null
        expect(model.get 'running').to.be.false

    context 'when the status is running', ->
      it 'return false', ->
        model.set 'status', 'running'
        expect(model.get 'running').to.be.true

    context 'when the status is stopped', ->
      it 'return false', ->
        model.set 'status', 'stopped'
        expect(model.get 'running').to.be.false
