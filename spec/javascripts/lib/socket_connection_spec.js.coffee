OriginalSockJS = window.SockJS

class FakeSockJS extends OriginalSockJS
  constructor: ->

describe 'AIO.SocketConnection', ->
  connection = null

  beforeEach ->
    window.SockJS = FakeSockJS
    connection = new AIO.SocketConnection 'https://example.com/sock'

  afterEach ->
    window.SockJS = OriginalSockJS

  describe 'constructor', ->
    it 'sets @serverURI', ->
      expect(connection.serverURI).to.equal 'https://example.com/sock'

    it 'initializes callback storage', ->
      expect(connection.nextCallbackId).to.equal 0
      expect(connection.callbacks).to.be.empty

    it 'is an event emitter', ->
      expect(connection).to.be.an.instanceof EventEmitter2

  describe '#connect', ->
    beforeEach ->
      connection.connect()

    it 'initializes a SockJS object', ->
      expect(connection.sock).to.be.an.instanceof SockJS

  context 'connection callbacks', ->
    event = null

    beforeEach ->
      sinon.stub connection, 'emit'
      event = sinon.spy()
      connection.connect()

    context 'on open', ->
      beforeEach ->
        sinon.stub connection, '_authenticate'
        connection.sock.onopen event

      it 'authenticates', ->
        expect(connection._authenticate).to.have.been.called

      it 'emits open event', ->
        expect(connection.emit).to.have.been.calledWith 'open', event

    context 'on close', ->
      beforeEach ->
        connection.sock.onclose event

      it 'emits close event', ->
        expect(connection.emit).to.have.been.calledWith 'close', event

  context 'on message', ->
    event = null

    beforeEach ->
      sinon.stub connection, 'emit'
      connection.connect()

    context 'when message is a valid json', ->
      context 'when json does not represent an array', ->
        beforeEach ->
          connection.sock.onmessage data: JSON.stringify({"foo": "bar"})

        it 'emits a message event with the object', ->
          expect(connection.emit).to.have.been.calledWith 'message', {"foo": "bar"}

      context 'when json represents an array', ->
        context 'when first element (namespace) and second element (event) are strings', ->
          beforeEach ->
            connection.sock.onmessage data: JSON.stringify(["foo", "bar", ["baz", 123]])

          it 'emits an event of the name (first item) with action name and arguments', ->
            expect(connection.emit).to.have.been.calledWith 'foo', 'bar', ['baz', 123]

        context 'when first element (namespace) is "global" and second element (event) is "callback"', ->
          beforeEach ->
            sinon.stub connection, 'invokeCallback'
            connection.sock.onmessage data: JSON.stringify(["global", "callback", [777, ['hello', 'world', 123]]])

          it 'emits an event of the name (first item) with action name and arguments', ->
            expect(connection.invokeCallback).to.have.been.calledWith 777, ['hello', 'world', 123]

        context "when first and second element aren't strings", ->
          it 'emits a message event with the object', ->
            connection.sock.onmessage data: JSON.stringify([1, "foo", 2])
            expect(connection.emit).to.have.been.calledWith 'message', [1, 'foo', 2]

            connection.emit.reset()
            connection.sock.onmessage data: JSON.stringify(["foo", 1, 2])
            expect(connection.emit).to.have.been.calledWith 'message', ['foo', 1, 2]

            connection.emit.reset()
            connection.sock.onmessage data: JSON.stringify([1, 2, 3])
            expect(connection.emit).to.have.been.calledWith 'message', [1, 2, 3]

    context 'when message is not json', ->
      beforeEach ->
        connection.sock.onmessage data: 'foo bar baz'

      it 'emits a message event with the string', ->
        expect(connection.emit).to.have.been.calledWith 'message', 'foo bar baz'

  describe '#registerCallback', ->
    it 'registers a callback and returns its id', ->
      expect(connection.callbacks).to.be.empty
      callback1 = -> 'foo'
      callback2 = -> 'bar'

      callback1Id = connection.registerCallback callback1
      callback2Id = connection.registerCallback callback2

      expect(connection.callbacks).to.have.length 2
      expect(connection.callbacks[callback1Id]).to.equal callback1
      expect(connection.callbacks[callback2Id]).to.equal callback2

  describe '#invokeCallback', ->
    context 'when callback with a given id exists', ->
      it 'finds callback by callback id, invokes it, and removes it', ->
        callback = sinon.spy()
        callbackId = connection.registerCallback callback
        expect(connection.callbacks[callbackId]).to.exist

        connection.invokeCallback callbackId, ['hello', 'world', 123]
        expect(callback).to.have.been.calledWith 'hello', 'world', 123
        expect(connection.callbacks[callbackId]).not.to.exist

    context 'when callback with a given id does not exist', ->
      it 'does not do anything', ->
        callback = sinon.spy()
        callbackId = connection.registerCallback callback
        expect(connection.callbacks[callbackId]).to.exist

        connection.invokeCallback callbackId + 1, ['hello', 'world', 123]
        expect(callback).not.to.have.been.called

  describe '#send', ->
    beforeEach ->
      connection.connect()
      sinon.stub connection.sock, 'send'

    context 'when a callback function is not given', ->
      it 'sends a message via socket connection in the form of [namespace, event, args, callback_id]', ->
        connection.send 'name', 'event', ['arg1', 'arg2', 123, 456]
        expect(connection.sock.send).to.have.been.calledWith JSON.stringify(['name', 'event', ['arg1', 'arg2', 123, 456]])

    context 'when a callback function is given', ->
      beforeEach ->
        sinon.stub connection, 'registerCallback'
        connection.registerCallback.returns 999

      it 'registers the callback function and sends a message with the callback id', ->
        callback = (hello) -> 'world'
        connection.send 'name', 'event', ['arg1', 123, callback]
        expect(connection.registerCallback).to.have.been.calledWith callback
        expect(connection.sock.send).to.have.been.calledWith JSON.stringify(['name', 'event', ['arg1', 123], 999])

  describe '#_authenticate', ->
    server = null

    beforeEach ->
      server = sinon.fakeServer.create()
      sinon.stub connection, 'send'

    afterEach ->
      server.restore()

    context 'when GET /rainbow/auth_token succeeds', ->
      token = 'My-Aw3s0m3-Au7h-T0k3n'

      beforeEach ->
        sinon.stub connection, 'emit'
        server.respondWith 'GET', '/rainbow/auth_token', [
          200,
          { 'Content-Type': 'application/json; charset=utf-8' },
          JSON.stringify(auth_token: token)
        ]
        connection._authenticate()
        server.respond()

      it 'sends "auth" message with the auth token and a callback that emits "authenticated" event', ->
        expect(connection.send).to.have.been.calledWith 'global', 'auth', sinon.match([token, sinon.match.func])

        expect(connection.emit).not.to.have.been.called
        connection.send.args[0][2][1]()
        expect(connection.emit).to.have.been.calledWith 'authenticated'

    context 'when GET /rainbow/auth_token fails', ->
      beforeEach ->
        server.respondWith 'GET', '/rainbow/auth_token', [
          401,
          { 'Content-Type': 'application/json; charset=utf-8' },
          JSON.stringify(error: 'You need to sign in or sign up before continuing.')
        ]
        connection._authenticate()
        server.respond()

      it 'does not send "auth" message', ->
        expect(connection.send).not.to.have.been.called
