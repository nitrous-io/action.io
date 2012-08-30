class AIO.SaveDialogViewModel extends AIO.ViewModel
  constructor: ->
    super()
    @documentVM = null
    @path = ko.observable(null)
    @errorMessage = ko.observable(null)
    @saving = ko.observable(false)

    if AIO.events
      AIO.events.on 'showSaveDialog', this.onShowSaveDialog

  reset: ->
    @documentVM = null
    @path(null)
    @errorMessage(null)
    @saving(false)

  validatePath: ->
    path = @path()
    path = $.trim(path) if path
    if !path || path.substr(-1) == '/'
      false
    else
      for pathComponent in path.split('/')
        unless pathComponent.match /^[^\/\\:\*\?"<>\|]*[^\/\\:\*\?"<>\|\.]+[^\/\\:\*\?"<>\|]*$/
          return false
      @path(path)
      true

  save: =>
    if this.validatePath()
      @saving(true)
      @errorMessage(null)
      path = '/' + @path()
      file = AIO.c.files.where(path)[0] || new AIO.File(path: path)
      parentDirectoryPath = path.split('/').slice(0, -1).join('/') + '/'
      parentDirectory = AIO.c.files.where(path: parentDirectoryPath)[0]
      callbackId = _.uniqueId('cb')
      content = @documentVM.content()

      AIO.callbacks[callbackId] = (err, path) =>
        delete AIO.callbacks[callbackId]
        @saving(false)
        if err
          if err.indexOf('aio_file_exists') != -1
            @errorMessage('A file already exists in the path.')
          else if err.indexOf('aio_folder_exists') != -1
            @errorMessage('A folder already exists in the path.')
          else
            @errorMessage(err)
          return

        fileVM = new AIO.FileViewModel(file)
        @documentVM.fileVM = fileVM
        @documentVM.fileVMObs(fileVM)
        parentDirectory?.files.add(file)
        this.hide()

      AIO.events.emit('newFile', path, content, callbackId)
    else
      @errorMessage('Invalid filename.')

  show: ->
    $('#save_dialog').modal('show')

  hide: =>
    this.reset()
    $('#save_dialog').modal('hide')

  onShowSaveDialog: (documentVM) =>
    this.reset()
    @documentVM = documentVM
    this.show()

  __destroy: ->
    if AIO.events
      AIO.events.off 'showSaveDialog', this.onShowSaveDialog
    delete @documentVM
    super()

