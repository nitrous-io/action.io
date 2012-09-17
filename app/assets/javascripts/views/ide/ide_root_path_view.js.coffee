AIO.IdeRootPathView = AIO.IdePathView.extend
  becomeFileManagementDelegate: (->
    if fsSocket = @get 'controller.fsSocket'
      fsSocket.set 'fileManagementDelegate', this
  ).observes 'controller.fsSocket'

  resignFileManagementDelegate: ->
    if fsSocket = @get 'controller.fsSocket'
      fsSocket.set 'fileManagementDelegate', null

  init: ->
    @_super()
    this.becomeFileManagementDelegate()

  willDestroy: ->
    @_super()
    this.resignFileManagementDelegate()

  didReceiveFileList: (err, pathString, fileList) ->
    content = @get 'content'
    if path = content.findByRelativePath pathString
      path.updateContent fileList

