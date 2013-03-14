AIO.VagrantIndexController = Em.ObjectController.extend
  init: ->
    @_super()

  reset: ->
    @set 'content', AIO.VagrantAccessToken.create()

  getAccessToken: ->
    @get('content').find()

