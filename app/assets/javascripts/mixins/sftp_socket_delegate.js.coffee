AIO.SftpSocketDelegate = Em.Mixin.create
  didReceiveFileList:     Em.required Function # (err, absolutePath, fileList)
  didReceiveFileContent:  Em.required Function # (err, absolutePath, content)
  didWriteFileContent:    Em.required Function # (err, absolutePath)
  didWriteNewFileContent: Em.required Function # (err, absolutePath)

