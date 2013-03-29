#= require eventemitter2

window.AIO ||= {}

class AIO.SocketConnection
  constructor: (@serverURI) ->
    @emitter = new EventEmitter2
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
    @emitter.emit 'open', event

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
          @emitter.emit namespace, event, args
          return
    @emitter.emit 'message', message

  _didClose: (event) ->
    @emitter.emit 'close', event

  emit: (name, event, args..., callback) ->
    if @sock
      if _.isFunction(callback)
        callbackId = this.registerCallback callback
        @sock.send JSON.stringify([name, event, args, callbackId])
      else
        @sock.send JSON.stringify([name, event, args.concat([callback])])

  addListener: ->
    @emitter.on _.toArray(arguments)...

  on: this::addListener

  once: ->
    @emitter.once _.toArray(arguments)...

  removeListener: ->
    @emitter.removeListener _.toArray(arguments)...

  removeAllListeners: ->
    @emitter.removeAllListeners _.toArray(arguments)...

  setMaxListeners: ->
    @emitter.setMaxListeners _.toArray(arguments)...

  listeners: ->
    @emitter.listeners _.toArray(arguments)...

