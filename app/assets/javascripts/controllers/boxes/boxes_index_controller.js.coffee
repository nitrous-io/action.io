AIO.BoxesIndexController = Em.ObjectController.extend
  contentBinding: 'AIO.router.boxesController'

  refresh: ->
    @get('content').findAll()

