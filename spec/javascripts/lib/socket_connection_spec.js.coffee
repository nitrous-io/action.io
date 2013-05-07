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

    it 'sets number of connection retries made to be 0', ->
      expect(connection.retries).to.equal 0

    it 'has a default timeout set', ->
      expect(connection.timeout).to.exist
      expect(connection.timeout).to.be.greaterThan 25

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
        sinon.stub connection, '_startTimeoutCheck'
        connection.retries = 5
        connection.sock.onopen event

      it 'sets @retries back to 0', ->
        expect(connection.retries).to.equal 0

      it 'authenticates', ->
        expect(connection._authenticate).to.have.been.called

      it 'starts timeout check', ->
        expect(connection._startTimeoutCheck).to.have.been.called

      it 'emits open event', ->
        expect(connection.emit).to.have.been.calledWith 'open', event

    context 'on close', ->
      beforeEach ->
        sinon.stub connection, '_stopTimeoutCheck'
        sinon.stub connection, '_retry'
        connection.sock.onclose event

      it 'emits close event', ->
        expect(connection.emit).to.have.been.calledWith 'close', event

      it 'stops timeout check', ->
        expect(connection._stopTimeoutCheck).to.have.been.called

      it 'calls _retry', ->
        expect(connection._retry).to.have.been.called

    context 'on heartbeat', ->
      clock = null

      beforeEach ->
        clock = sinon.useFakeTimers +new Date

      afterEach ->
        clock.restore()

      doAction = ->
        connection.sock.onheartbeat event

      it 'sets lastHeartbeat to be current time', ->
        expect(connection.lastHeartbeat).not.to.exist
        doAction()
        expect(connection.lastHeartbeat).to.equal +new Date
        clock.tick 1000
        doAction()
        expect(connection.lastHeartbeat).to.equal +new Date

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
    beforeEach ->
      sinon.stub connection, 'send'

    context 'when GET /rainbow/auth_token succeeds', ->
      token = 'My-Aw3s0m3-Au7h-T0k3n'

      beforeEach ->
        sinon.stub connection, 'emit'
        server.respondWith 'GET', '/rainbow/auth_token', [
          200
          { 'Content-Type': 'application/json; charset=utf-8' }
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

  describe '#_retry', ->
    clock = null

    beforeEach ->
      clock = sinon.useFakeTimers +new Date
      sinon.stub connection, '_destroySock'
      sinon.stub connection, 'connect'

    afterEach ->
      clock.restore()

    doAction = ->
      connection._retry()

    context 'always', ->
      beforeEach ->
        doAction()

      it 'increments @retries by 1', ->
        expect(connection.retries).to.equal 1

      it 'calls _destroySock', ->
        expect(connection._destroySock).to.have.been.called

    context 'when number of retries <= 5', ->
      it 'reattempts connecting after 1 seconds', ->
        makeAssertion = ->
          clock.tick 999
          expect(connection.connect).not.to.have.been.called
          clock.tick 1
          expect(connection.connect).to.have.been.called

        connection.retries = 0
        doAction()
        makeAssertion()

        connection.connect.reset()
        connection.retries = 4
        doAction()
        makeAssertion()

    context 'when 5 < number of retries <= 10', ->
      it 'reattempts connecting after 5 seconds', ->
        makeAssertion = ->
          clock.tick 4999
          expect(connection.connect).not.to.have.been.called
          clock.tick 1
          expect(connection.connect).to.have.been.called

        connection.retries = 5
        doAction()
        makeAssertion()

        connection.connect.reset()
        connection.retries = 9
        doAction()
        makeAssertion()

    context 'when number of retries > 10', ->
      it 'reattempts connecting after 10 seconds', ->
        connection.retries = 10
        doAction()
        clock.tick 9999
        expect(connection.connect).not.to.have.been.called
        clock.tick 1
        expect(connection.connect).to.have.been.called

  describe '#_startTimeoutCheck', ->
    clock = null

    beforeEach ->
      clock = sinon.useFakeTimers +new Date
      connection.sock = { close: sinon.spy() }

    afterEach ->
      clock.restore()
      window.clearInterval connection.timeoutCheck

    doAction = ->
      connection._startTimeoutCheck()

    it 'sets @lastHeartbeat to be current time', ->
      doAction()
      expect(connection.lastHeartbeat).to.equal +new Date

    context 'every timeout check interval', ->
      it 'checks whether @lastHeartbeat is more than @timeout seconds ago and closes connection if so', ->
        doAction()
        clock.tick connection.timeoutCheckInterval * 1000
        expect(connection.sock.close).not.to.have.been.called
        clock.tick (connection.timeout - connection.timeoutCheckInterval) * 1000
        expect(connection.sock.close).to.have.been.called

  describe '#_stopTimeoutCheck', ->
    beforeEach ->
      sinon.stub window, 'clearInterval'

    afterEach ->
      window.clearInterval.restore()

    doAction = ->
      connection._stopTimeoutCheck()

    context 'when @timeoutCheck is not set', ->
      beforeEach ->
        connection.timeoutCheck = null
        doAction()

      it 'does not clear the timeout check', ->
        expect(window.clearInterval).not.to.have.been.called

    context 'when @timeoutCheck is already set', ->
      dummy = null

      beforeEach ->
        dummy = sinon.spy()
        connection.timeoutCheck = dummy
        doAction()

      it 'clears timeout check', ->
        expect(window.clearInterval).to.have.been.calledWith dummy
        expect(connection.timeoutCheck).not.to.exist
