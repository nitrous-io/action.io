AIO.FileManagementDelegate = Em.Mixin.create
  becomeFileManagementDelegate: (->
    if fsSocket = @get 'controller.fsSocket'
      fsSocket.set 'fileManagementDelegate', this
  ).observes 'controller.fsSocket'

  resignFileManagementDelegate: ->
    if fsSocket = @get 'controller.fsSocket'
      fsSocket.set 'fileManagementDelegate', null

  didReceiveFileList: Em.required Function # (err, absolutePath, fileList)

