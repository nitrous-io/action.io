AIO.SftpSocket = AIO.BaseSocket.extend
  name: 'sftp'
  box: null
  started: false
  startedFirstTime: false
  startedAt: null

  serverURIBinding: 'box.box_server_uri'
  serverName: 'rainbow'

  connect: ->
    console.log 'calling _super'
    @_super()
    console.log 'starting connection'
    @set 'startedAt', Date.now()
    console.log 'started connection'


  didConnect: ->
    @_super()
    boxId = @get 'box.id'
    socket = @get 'socket'

    socket.send 'start', boxId, =>
      @set 'started', true
      @set('startedFirstTime', true) if !@get('startedFirstTime')
      duration = Date.now() - @get('startedAt')
      region   = @get('box.region')
      host     = @get('box.host')

      AIO.TimingMetrics.record 'sftp_connection', duration, region, host

  didClose: ->
    @_super()
    @set 'started', false

  disconnect: ->
    @_super()
    @setProperties
      startedFirstTime: false
      started: false
      startedAt: null
      box: null

  fetchFileList: (absolutePath, callback) ->
    @send 'list', absolutePath, callback

  fetchFileContent: (absolutePath, callback) ->
    @send 'read', absolutePath, callback

  downloadFile: (absolutePath, callback) ->
    @send 'download', absolutePath, callback

  writeFile: (absolutePath, content, callback) ->
    @send 'write', absolutePath, content, callback

  writeNewFile: (absolutePath, content, callback) ->
    @send 'writeNew', absolutePath, content, callback

  makeDirectory: (absolutePath, callback) ->
    @send 'makeDir', absolutePath, callback

  sendUploadToken: (absolutePath, token, callback) ->
    @send 'upload', absolutePath, token, callback

  deleteFile: (absolutePath, callback) ->
    @send 'deleteFile', absolutePath, callback

  deleteDir: (absolutePath, callback) ->
    @send 'deleteDir', absolutePath, callback

  rename: (currentPath, newPath, callback) ->
    @send 'rename', currentPath, newPath, callback
