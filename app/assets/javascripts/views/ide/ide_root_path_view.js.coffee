AIO.IdeRootPathView = AIO.IdePathView.extend
  didInsertElement: ->
    @_super()
    if fsSocket = @get 'controller.fsSocket'
      fsSocket.set 'fileManagementDelegate', this

  willDestroy: ->
    @_super()
    if fsSocket = @get 'controller.fsSocket'
      fsSocket.set 'fileManagementDelegate', null

  didReceiveFileList: (err, pathString, fileList) ->
    content = @get 'content'
    if path = content.findByRelativePath pathString
      path.updateContent fileList

