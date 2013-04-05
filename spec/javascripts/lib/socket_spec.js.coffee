describe 'AIO.Socket', ->
  socket = connection = null

  beforeEach ->
    connection = new AIO.SocketConnection 'https://example.com/ws'
    socket = new AIO.Socket 'mysock', connection

  describe 'constructor', ->
    it 'sets @name and @socketConnection', ->
      expect(socket.name).to.equal 'mysock'
      expect(socket.socketConnection).to.equal connection

    it 'is an event emitter', ->
      expect(socket).to.be.an.instanceof EventEmitter2

  describe '#send', ->
    beforeEach ->
      sinon.stub connection, 'send'

    it 'sends an event to the socket connection object', ->
      socket.send 'foo'
      expect(connection.send).to.have.been.calledWith 'mysock', 'foo', []

      connection.send.reset()
      socket.send 'foo', 'bar', 'baz', 123
      expect(connection.send).to.have.been.calledWith 'mysock', 'foo', ['bar', 'baz', 123]

      connection.send.reset()
      callback = (hello) -> 'world'
      socket.send 'foo', 'bar', callback
      expect(connection.send).to.have.been.calledWith 'mysock', 'foo', ['bar', callback]
