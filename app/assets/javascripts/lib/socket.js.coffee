#= require eventemitter2

window.AIO ||= {}

class AIO.Socket
  constructor: (@name, @socketConnection) ->
    @emitter = new EventEmitter2
    @socketConnection.on @name, (action, args) =>
      @emitter.emit action, args...

  destroy: ->
    @socketConnection.removeAllListeners()
    this.removeAllListeners()

  emit: (event, args...) ->
    @socketConnection.emit @name, event, args

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

