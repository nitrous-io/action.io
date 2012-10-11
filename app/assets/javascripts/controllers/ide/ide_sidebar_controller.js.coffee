AIO.IdeSidebarController = Em.ArrayController.extend
  homePath: null # home (~/) path
  rootPath: null # current root path in the sidebar
  content:  null # array of all path objects

  hiddenFilesVisible: false

  initialize: ->
    @set 'homePath', homePath = AIO.Path.create absolutePath: '', directory: true
    @set 'rootPath', homePath
    @set 'content', [homePath]

  reset: ->
    @set 'homePath', null
    @set 'rootPath', null
    @set 'content', null

  openPath: (path) ->
    sftpSocketStarted = AIO.get 'router.ideController.sftpSocket.started'
    if !path.get('loading') && sftpSocketStarted
      if path.get 'directory'
        path.set 'expanded', !path.get('expanded')
        if path.get 'expanded'
          this.fetchFileList path
      else
        editorController = AIO.get 'router.ideEditorController'
        if document = editorController.findProperty 'path', path
          editorController.makeTabActive document
        else
          this.fetchFileContent path

  fetchFileList: (path) ->
    sftpSocket = AIO.get 'router.ideController.sftpSocket'
    path.incrementProperty 'loadCount'
    sftpSocket.fetchFileList path.get 'absolutePath'

  fetchFileContent: (path) ->
    sftpSocket = AIO.get 'router.ideController.sftpSocket'
    path.incrementProperty 'loadCount'
    sftpSocket.fetchFileContent path.get 'absolutePath'

  refresh: (path) ->
    if path.get('directory') && path.get('expanded')
      delay = 0

      for p in path.get 'arrangedContent'
        if p.get('directory') && p.get('expanded')
          delay += @constructor.REFRESH_DELAY
          ((controller, p, delay) ->
            window.setTimeout ->
              controller.refresh p
            , delay
          )(this, p, delay)

      unless path.get 'loading'
        this.fetchFileList path

  refreshAll: ->
    this.refresh @get('rootPath')

  setHomeAsRoot: ->
    @set 'rootPath', @get('homePath')

  setPathAsRoot: (path) ->
    @set 'rootPath', path

AIO.IdeSidebarController.reopenClass
  REFRESH_DELAY: 500

