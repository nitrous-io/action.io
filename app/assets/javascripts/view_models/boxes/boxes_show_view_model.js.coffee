class AIO.BoxesShowViewModel extends AIO.ViewModel
  constructor: (model) ->
    super(model)
    @currentUser = kb.viewModel(AIO.currentUser)

    @previewUri = ko.computed =>
      if @name?() && @host?()
        "http://#{@name()}.#{@host()}"

    this.setupMainMenu()

    @console = new AIO.ConsoleViewModel(@model())
    @fsSocketReady = ko.observable(false)
    @fsSocket = new AIO.FSSocketViewModel(@model())
    @rootFile = new AIO.FileViewModel(new AIO.File(path: '/'))
    @editor = new AIO.EditorViewModel
    @saveDialog = new AIO.SaveDialogViewModel

    @fsSocket.connect (err, socket) =>
      return if err
      @rootFile.expanded(true)

      socket.on 'list', (err, path, vmid, fileList) =>
        AIO.events.emit 'fileListReceived', err, path, vmid, fileList

      socket.on 'read', (err, path, vmid, content) =>
        AIO.events.emit 'fileContentReceived', err, path, vmid, content, @editor

      socket.on 'write', (err, path, vmid) =>
        AIO.events.emit 'fileWritten', err, path, vmid

      socket.on 'new', (err, path, callbackId) =>
        cb = AIO.callbacks[callbackId]
        cb?(err, path)

      @fsSocketReady(true)

  showBetaNotice: ->
    $('#beta_notice').modal('show')

  comingSoon: ->
    AIO.showAlertDialog('Feature Coming Soon', 'This feature is coming soon!')

  __destroy: ->
    super()
    AIO.c.files.reset()
    AIO.c.documents.reset()

  setupMainMenu: ->
    menu = (name, items) -> new AIO.MenuViewModel(name, items)
    menuItem = (name, macKey, windowsKey, action) -> new AIO.MenuItemViewModel(name, macKey, windowsKey, action)

    @mainMenu = menu 'Main Menu', [
      menu 'Action.IO', [
        menuItem 'About Action.IO'
      ]
      menu 'File', [
        menuItem 'New', null, null, =>
          @editor.newDocument()
        menuItem 'Save', null, null, =>
          @editor.currentTab()?.saveFile()
        menuItem '---'
        menuItem 'Close', null, null, =>
          if currentTab = @editor.currentTab()
            @editor.closeTab(currentTab)
      ]
      menu 'Edit', [
        menuItem 'Coming Soon'
      ]
      menu 'Collaborate', [
        menuItem 'Coming Soon'
      ]
      menu 'Preview', [
        menuItem 'localhost:3000', null, null, @previewUri() + ':3000/'
        menuItem 'localhost:4000', null, null, @previewUri() + ':4000/'
      ]
      menu 'Deploy', [
        menuItem 'Coming Soon'
      ]
      menu 'Help', [
        menuItem 'Coming Soon'
      ]
    ]

