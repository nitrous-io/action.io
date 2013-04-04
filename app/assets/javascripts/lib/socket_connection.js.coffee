#= require sockjs-0.3.4
#= require eventemitter2

window.AIO ||= {}

class AIO.SocketConnection extends EventEmitter2
  constructor: (@serverURI) ->
    @nextCallbackId = 0
    @callbacks = []

  connect: ->
    @sock = new SockJS(@serverURI, devel: true)
    @sock.onopen    = _.bind(@_didOpen, this)
    @sock.onmessage = _.bind(@_didReceiveMessage, this)
    @sock.onclose   = _.bind(@_didClose, this)

  registerCallback: (callback) ->
    callbackId = @nextCallbackId++
    @callbacks[callbackId] = callback
    callbackId

  invokeCallback: (callbackId, args) ->
    if callback = @callbacks[callbackId]
      @callbacks[callbackId] = null
      callback args...

  destroy: ->
    this.removeAllListeners()
    @callbacks = []
    @sock.onopen = null
    @sock.onmessage = null
    @sock.onclose = null
    @sock = null

  _didOpen: (event) ->
    this._authenticate()
    this.emit 'open', event

  _authenticate: ->
    $.get('/rainbow/auth_token').done (data) =>
      if data.auth_token?
        this.send 'global', 'auth', [data.auth_token, (=>
          this.emit 'authenticated'
        )]

  _didReceiveMessage: (event) ->
    message = event.data
    try
      message = JSON.parse message
    if message instanceof Array
      [namespace, event, args] = message
      if _.isString(namespace) && _.isString(event)
        if namespace == 'global' && event == 'callback'
          [callbackId, callbackArgs] = args
          this.invokeCallback callbackId, callbackArgs
        else
          this.emit namespace, event, args
          return
    this.emit 'message', message

  _didClose: (event) ->
    this.emit 'close', event

  send: (name, event, args) ->
    if @sock
      if _.isFunction(_.last args)
        callback = args.pop()
        callbackId = this.registerCallback callback
        @sock.send JSON.stringify([name, event, args, callbackId])
      else
        @sock.send JSON.stringify([name, event, args])

