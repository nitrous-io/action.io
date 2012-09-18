AIO.FileContentDelegate = Em.Mixin.create
  didReceiveFileContent: Em.required Function # (err, absolutePath, content)
  didWriteFileContent: Em.required Function # (err, absolutePath)

