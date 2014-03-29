describe 'App.Part', ->
  model = null

  beforeEach ->
    model = App.Part.create()

  describe 'humanized', ->
    context 'when package description follows the convention (Name: Description)', ->
      beforeEach ->
        model.set 'name', 'ack'
        model.set 'description', 'Ack: A tool like grep, optimized for programmers'

      it 'returns the humanized name', ->
        expect(model.get 'humanized.name').to.eql 'Ack'

      it 'returns the humanized description', ->
        expect(model.get 'humanized.description').to.eql 'A tool like grep, optimized for programmers'

    context 'when package description does not follow the convention', ->
      beforeEach ->
        model.set 'name', 'the_silver_searcher'
        model.set 'description', 'A code-searching tool similar to ack, with focus on speed'

      it 'returns the humanized name', ->
        expect(model.get 'humanized.name').to.eql 'The silver searcher'

      it 'returns the humanized description', ->
        expect(model.get 'humanized.description').to.eql 'A code-searching tool similar to ack, with focus on speed'

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
