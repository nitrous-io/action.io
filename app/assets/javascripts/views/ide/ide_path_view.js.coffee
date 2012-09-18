AIO.IdePathView = Em.View.extend
  templateName: 'templates/ide/path'
  content: null

  didClick: ->
    path = @get 'content'
    if path && !path.get('loading') && fsSocket = @get 'controller.fsSocket'
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

