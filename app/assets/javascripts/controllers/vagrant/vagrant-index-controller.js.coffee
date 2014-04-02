App.VagrantIndexController = Em.ObjectController.extend
  init: ->
    @_super()

  reset: ->
    @set 'content', App.VagrantAccessToken.create()

  getAccessToken: ->
    @get('content').find()

