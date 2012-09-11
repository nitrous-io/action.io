AIO.Menu = Em.Object.extend
  name: null
  items: null

  init: ->
    @_super()
    @set 'items', [] unless @get 'items'

