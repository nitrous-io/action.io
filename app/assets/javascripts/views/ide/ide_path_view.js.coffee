AIO.IdePathView = Em.View.extend
  templateName: 'templates/ide/path'
  content: null

  didClick: ->
    path = @get 'content'
    path.set 'expanded', !path.get('expanded')
    if path.get 'expanded'
      if fsSocket = @get 'controller.fsSocket'
        fsSocket.fetchFileList path.get('absolutePath')

