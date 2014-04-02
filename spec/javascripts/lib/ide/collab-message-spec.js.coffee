describe 'App.CollabMessage', ->
  klass = App.CollabMessage
  collabMessage = null

  beforeEach ->
    collabMessage = klass.create username: 'foo', data: 'bar'

  describe '#chatMessage', ->
    context 'for chat messages', ->
      beforeEach ->
        collabMessage.set 'type', klass.TypeChat

      it 'returns true', ->
        expect(collabMessage.get 'isChatMessage').to.be.true

    context 'for other messages', ->
      it 'returns false', ->
        collabMessage.set 'type', klass.TypeFileOpen
        expect(collabMessage.get 'isChatMessage').to.be.false
        collabMessage.set 'type', klass.TypeCollabMode
        expect(collabMessage.get 'isChatMessage').to.be.false

    context 'for messages with undefined type (from early API)', ->
      beforeEach ->
        collabMessage.set 'type', undefined

      it 'returns true', ->
        expect(collabMessage.get 'isChatMessage').to.be.true

  describe '#hasFileLink', ->
    context 'for file open and collab mode events', ->
      it 'returns true', ->
        collabMessage.set 'type', klass.TypeFileOpen
        expect(collabMessage.get 'hasFileLink').to.be.true
        collabMessage.set 'type', klass.TypeCollabMode
        expect(collabMessage.get 'hasFileLink').to.be.true

    context 'for other messages', ->
      it 'returns false', ->
        collabMessage.set 'type', klass.TypeChat
        expect(collabMessage.get 'hasFileLink').to.be.false
        collabMessage.set 'type', undefined
        expect(collabMessage.get 'hasFileLink').to.be.false
