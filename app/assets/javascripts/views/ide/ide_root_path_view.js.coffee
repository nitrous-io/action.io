AIO.IdeRootPathView = AIO.IdePathView.extend
  becomeFileManagementDelegate: (->
    if fsSocket = @get 'controller.fsSocket'
      fsSocket.set 'fileManagementDelegate', this
  ).observes 'controller.fsSocket'

  willDestroy: ->
    @_super()
    if fsSocket = @get 'controller.fsSocket'
      fsSocket.set 'fileManagementDelegate', null

  didReceiveFileList: (err, pathString, fileList) ->
    content = @get 'content'
    if path = content.findByRelativePath pathString
      path.updateContent fileList

