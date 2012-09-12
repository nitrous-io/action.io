AIO.IdeController = Em.ObjectController.extend
  documents: null
  consoleSessions: null
  homePath: null
  rootPath: null

  init: ->
    @_super()
    @set 'documents', []
    @set 'consoleSessions', []
    @set 'homePath', AIO.Path.create absolutePath: ''
    @set 'rootPath', @get('homePath')

  setContentByBoxId: (id) ->
    box = AIO.get('router.boxesController').findById(id) || AIO.Box.create id: id
    box.findResource()
    @set 'content', box

