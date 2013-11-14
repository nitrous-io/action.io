AIO.SftpSocket = AIO.BaseSocket.extend
  namespace: 'sftp'

  fetchFileList: (absolutePath, callback) ->
    this.send 'list', absolutePath, callback

  fetchFileContent: (absolutePath, callback) ->
    this.send 'read', absolutePath, callback

  downloadFile: (absolutePath, callback) ->
    this.send 'download', absolutePath, callback

  writeFile: (absolutePath, content, callback) ->
    this.send 'write', absolutePath, content, callback

  writeNewFile: (absolutePath, content, callback) ->
    this.send 'writeNew', absolutePath, content, callback

  makeDirectory: (absolutePath, callback) ->
    this.send 'makeDir', absolutePath, callback

  sendUploadToken: (absolutePath, token, callback) ->
    this.send 'upload', absolutePath, token, callback

  deleteFile: (absolutePath, callback) ->
    this.send 'deleteFile', absolutePath, callback

  deleteDir: (absolutePath, callback) ->
    this.send 'deleteDir', absolutePath, callback

  rename: (currentPath, newPath, callback) ->
    this.send 'rename', currentPath, newPath, callback
