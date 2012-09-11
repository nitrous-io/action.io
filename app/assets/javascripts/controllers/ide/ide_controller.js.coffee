AIO.IdeController = Em.ObjectController.extend
  documents: null
  consoleSessions: null

  init: ->
    @_super()
    @set 'documents', []
    @set 'consoleSessions', []

  setContentByBoxId: (id) ->
    box = AIO.get('router.boxesController').findById(id) || AIO.Box.create id: id
    box.findResource()
    @set 'content', box

