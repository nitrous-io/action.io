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
        if document = AIO.get('router.ideController.documents').findProperty 'path', path
          editorView = AIO.get('router.applicationController.view.editorView').makeTabActive document
        else
          path.incrementProperty 'loadCount'
          fsSocket.fetchFileContent path.get 'absolutePath'

