describe 'App.BaseSocket', ->
  baseSocket = null

  beforeEach ->
    baseSocket = App.BaseSocket.create(name: 'foo', serverURI: 'https://example.com', serverName: 'rainbow')

  describe '#connect', ->
    socket = connection = null

    beforeEach ->
      sinon.stub App.SocketConnection.prototype, 'connect'
      sinon.stub baseSocket, 'didClose'
      baseSocket.connect()
      connection = baseSocket.get 'connection'
      socket = baseSocket.get 'socket'

    afterEach ->
      App.SocketConnection::connect.restore()

    it 'initializes SocketConnection and Socket classes and then connects', ->
      expect(connection).to.be.an.instanceOf App.SocketConnection
      expect(connection.serverURI).to.equal 'https://example.com/ws'
      expect(connection.serverName).to.equal 'rainbow'
      expect(socket).to.be.an.instanceOf App.Socket
      expect(socket.name).to.equal 'foo'
      expect(socket.socketConnection).to.equal connection
      expect(connection.connect).to.have.been.called

    it 'sets up event handlers for "authenticated" and "close" events', ->
      expect(baseSocket.didClose).not.to.have.been.called
      baseSocket.connection.emit 'close'
      expect(baseSocket.didClose).to.have.been.called

    context 'when "authenticated" event is invoked', ->
      beforeEach ->
        sinon.stub baseSocket, 'didConnect'
        sinon.stub socket, 'send'

      it 'sends "init" message via socket connection with "didConnect" as a callback', ->
        baseSocket.connection.emit 'authenticated'
        expect(socket.send).to.have.been.calledWith 'init'
        expect(baseSocket.didConnect).not.to.have.been.called
        socket.send.yield()
        expect(baseSocket.didConnect).to.have.been.called

  describe '#disconnect', ->
    context 'when "connection" property is present', ->
      beforeEach ->
        sinon.stub baseSocket, 'didClose'
        baseSocket.set 'connection', sinon.stub destroy: (->)
        baseSocket.set 'socket', sinon.spy()

      it 'calls destroy on connection and sets socket and connection properties to be null', ->
        connection = baseSocket.get 'connection'
        expect(connection.destroy).not.to.have.been.called
        baseSocket.disconnect()
        expect(connection.destroy).to.have.been.called
        expect(baseSocket.didClose).to.have.been.called
        expect(baseSocket.get 'connection').not.to.exist
        expect(baseSocket.get 'socket').not.to.exist

    context 'when "connection" property is null', ->
      beforeEach ->
        baseSocket.set 'connection', null
        baseSocket.set 'socket', sinon.spy()

      it 'just nullifies socket object if it exists', ->
        expect(baseSocket.get 'socket').to.exist
        baseSocket.disconnect()
        expect(baseSocket.get 'socket').not.to.exist

  describe '#send', ->
    context 'when socket property is present', ->
      beforeEach ->
        baseSocket.set 'socket', sinon.stub send: (->)

      it 'delegates to socket object', ->
        socket = baseSocket.get 'socket'
        expect(socket.send).not.to.have.been.called
        baseSocket.send 'hello', 'world', 123
        expect(socket.send).to.have.been.calledWith 'hello', 'world', 123

    context 'when socket property is null', ->
      beforeEach ->
        baseSocket.set 'socket', null

      it 'does nothing', ->
        expect(->
          baseSocket.send('hello', 'world', 123)
        ).not.to.throw Error
