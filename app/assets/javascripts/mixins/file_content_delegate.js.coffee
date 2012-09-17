AIO.FileContentDelegate = Em.Mixin.create
  becomeFileContentDelegate: (->
    if fsSocket = @get 'controller.fsSocket'
      fsSocket.set 'fileContentDelegate', this
  ).observes 'controller.fsSocket'

  resignFileContentDelegate: ->
    if fsSocket = @get 'controller.fsSocket'
      fsSocket.set 'fileContentDelegate', null

  didReceiveFileContent: Em.required Function # (err, absolutePath, content)
  didWriteFileContent: Em.required Function # (err, absolutePath)

