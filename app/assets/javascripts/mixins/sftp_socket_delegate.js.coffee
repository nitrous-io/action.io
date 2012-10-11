AIO.SftpSocketDelegate = Em.Mixin.create
  sftpSocketDidStartForTheFirstTime: Em.required Function # (sftpSocket)
  sftpSocketDidReceiveFileList:      Em.required Function # (sftpSocket, err, absolutePath, fileList)
  sftpSocketDidReceiveFileContent:   Em.required Function # (sftpSocket, err, absolutePath, content)
  sftpSocketDidWriteFileContent:     Em.required Function # (sftpSocket, err, absolutePath)
  sftpSocketDidWriteNewFileContent:  Em.required Function # (sftpSocket, err, absolutePath)

