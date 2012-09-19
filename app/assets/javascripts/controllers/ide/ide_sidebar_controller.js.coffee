AIO.IdeSidebarController = Em.ObjectController.extend
  homePath: null # home (~/) path
  content:  null # current path

  initialize: ->
    @set 'homePath', homePath = AIO.Path.create absolutePath: ''
    @set 'content',  homePath

  reset: ->
    @set 'homePath', null
    @set 'content',  null

  openPath: (path) ->
    fsSocketStarted = AIO.get 'router.ideController.fsSocket.started'
    if !path.get('loading') && fsSocketStarted
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
    fsSocket = AIO.get 'router.ideController.fsSocket'
    path.incrementProperty 'loadCount'
    fsSocket.fetchFileList path.get 'absolutePath'

  fetchFileContent: (path) ->
    fsSocket = AIO.get 'router.ideController.fsSocket'
    path.incrementProperty 'loadCount'
    fsSocket.fetchFileContent path.get 'absolutePath'

  refreshAll: ->
    this.refresh @get('content')

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

AIO.IdeSidebarController.reopenClass
  REFRESH_DELAY: 500

