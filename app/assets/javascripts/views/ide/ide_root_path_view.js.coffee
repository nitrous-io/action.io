AIO.IdeRootPathView = AIO.IdePathView.extend AIO.FileManagementDelegate,
  init: ->
    @_super()
    this.becomeFileManagementDelegate()

  willDestroy: ->
    @_super()
    this.resignFileManagementDelegate()

  didReceiveFileList: (err, pathString, fileList) ->
    homePath = @get 'controller.homePath'
    if path = homePath.findByRelativePath pathString
      path.decrementProperty 'loadCount'
      unless err
        path.updateContent fileList

