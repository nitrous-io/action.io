class AIO.EventEmitter extends EventEmitter
  constructor: ->
    super
    this.setMaxListeners(0)

  reset: ->
    this.removeAllListeners()

