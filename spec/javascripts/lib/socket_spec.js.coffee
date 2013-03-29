describe 'AIO.Socket', ->
  socket = connection = null

  beforeEach ->
    connection = new AIO.SocketConnection 'https://example.com/sock'
    socket = new AIO.Socket 'mysock', connection

  describe 'constructor', ->
    it 'sets @name and @socketConnection', ->
      expect(socket.name).to.equal 'mysock'
      expect(socket.socketConnection).to.equal connection

    it 'initializes an event emitter', ->
      expect(socket.emitter).to.be.an.instanceof EventEmitter2

  describe '#on', ->
    it 'registers a listener to socket events', ->
      callback = sinon.spy()
      socket.on 'bar', callback
      connection.emitter.emit 'mysock', 'bar', ['baz', 123]
      expect(callback).to.have.been.calledWith 'baz', 123

      callback.reset()
      connection.emitter.emit 'mysock', 'bar', ['qux', true]
      expect(callback).to.have.been.calledWith 'qux', true

  describe '#once', ->
    it 'registers a one-time listener to socket events', ->
      callback = sinon.spy()
      socket.once 'bar', callback
      connection.emitter.emit 'mysock', 'bar', ['baz', 123]
      expect(callback).to.have.been.calledWith 'baz', 123

      callback.reset()
      connection.emitter.emit 'mysock', 'bar', ['qux', true]
      expect(callback).not.to.have.been.called

  describe '#emit', ->
    beforeEach ->
      sinon.stub connection, 'emit'

    it 'sends an event to the socket connection object', ->
      socket.emit 'foo'
      expect(connection.emit).to.have.been.calledWith 'mysock', 'foo', []

      connection.emit.reset()
      socket.emit 'foo', 'bar', 'baz', 123
      expect(connection.emit).to.have.been.calledWith 'mysock', 'foo', ['bar', 'baz', 123]

      connection.emit.reset()
      callback = (hello) -> 'world'
      socket.emit 'foo', 'bar', callback
      expect(connection.emit).to.have.been.calledWith 'mysock', 'foo', ['bar', callback]

