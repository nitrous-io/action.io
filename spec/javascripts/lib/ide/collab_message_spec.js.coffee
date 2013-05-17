describe 'AIO.CollabMessage', ->
  klass = AIO.CollabMessage

  describe '#chatMessage', ->
    collabMessage = null

    context 'for chat messages', ->
      beforeEach ->
        collabMessage = klass.create username: 'foo', message: 'hello world', messageType: AIO.CollabMessage.chat

      it 'returns true', ->
        expect(collabMessage.get 'isChatMessage').to.be.true

    context 'for other messages', ->
      beforeEach ->
        collabMessage = klass.create username: 'foo', message: 'hello world', messageType: AIO.CollabMessage.fileOpen

      it 'returns false', ->
        expect(collabMessage.get 'isChatMessage').to.be.false

    context 'for messages with undefined type (from early API)', ->
      beforeEach ->
        collabMessage = klass.create username: 'foo', message: 'hello world', messageType: undefined

      it 'returns true', ->
        expect(collabMessage.get 'isChatMessage').to.be.true

  describe '#messageFragment', ->
    collabMessage = null

    context 'for fileOpen message', ->
      beforeEach ->
        collabMessage = klass.create username: 'foo', message: 'path/to/file', messageType: AIO.CollabMessage.fileOpen

      it 'sets the correct fragment', ->
        expect(collabMessage.get 'messageFragment').to.equal 'has open'

    context 'for collabMode message', ->
      beforeEach ->
        collabMessage = klass.create username: 'foo', message: 'path/to/file', messageType: AIO.CollabMessage.collabMode

      it 'sets the correct fragment', ->
        expect(collabMessage.get 'messageFragment').to.equal 'enabled collab mode on'

  describe '#filePath', ->
    collabMessage = null

    context 'for a file status message', ->
      beforeEach ->
        collabMessage = klass.create username: 'foo', message: 'path/to/file', messageType: AIO.CollabMessage.fileOpen

      it 'is the message itself', ->
        expect(collabMessage.get 'filePath').to.equal 'path/to/file'

    context 'for a chat message', ->
      beforeEach ->
        collabMessage = klass.create username: 'foo', message: 'hello', messageType: AIO.CollabMessage.chat

      it 'is null', ->
        expect(collabMessage.get 'filePath').to.be.undefined
