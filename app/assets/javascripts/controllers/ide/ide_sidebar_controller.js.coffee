AIO.IdeSidebarController = Em.ObjectController.extend
  homePath: null # home (~/) path
  content:  null # current path

  initialize: ->
    @set 'homePath', homePath = AIO.Path.create absolutePath: ''
    @set 'content',  homePath

  reset: ->
    @set 'homePath', null
    @set 'content',  null

  openPath: (path) ->
    fsSocket = AIO.get 'router.ideController.fsSocket'
    if !path.get('loading') && fsSocket
      if path.get 'directory'
        path.set 'expanded', !path.get('expanded')
        if path.get 'expanded'
          path.incrementProperty 'loadCount'
          fsSocket.fetchFileList path.get 'absolutePath'
      else
        editorController = AIO.get 'router.ideEditorController'
        if document = editorController.findProperty 'path', path
          editorController.makeTabActive document
        else
          path.incrementProperty 'loadCount'
          fsSocket.fetchFileContent path.get 'absolutePath'

