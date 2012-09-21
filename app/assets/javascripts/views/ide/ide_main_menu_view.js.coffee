menu = (name, items) -> AIO.Menu.create(name: name, items: items)
menuItem = (name, attrs={}) ->
  attrs.name = name
  AIO.MenuItem.create(attrs)
separator = AIO.MenuItem.create(separator: true)

AIO.IdeMainMenuView = Em.View.extend
  templateName: 'templates/ide/main_menu'
  elementId: 'ide_main_menu_view'

  menu: [
    menu 'Action.IO', [
      menuItem 'About Action.IO'
    ]
    menu 'File', [
      menuItem 'New', macKey: 'shift+ctrl+n', pcKey: 'ctrl+n', callback: (controller) ->
        controller.fileNew()
      menuItem 'Save',
        macKey: ['command+s', 'ctrl+s'], pcKey:'ctrl+s',
        disabledBinding: 'AIO.router.ideEditorController.hasNoTab',
        callback: (controller) ->
          controller.fileSave()
      separator
      menuItem 'Close',
        macKey: 'ctrl+w', pcKey: 'ctrl+w',
        disabledBinding: 'AIO.router.ideEditorController.hasNoTab',
        callback: (controller) ->
          controller.fileClose()
    ]
    menu 'Preview',
      _.map [3000, 4000, 8080, 8888], (port) ->
        menuItem "Port #{port}",
          boxHostBinding: 'AIO.router.ideController.content.boxHost'
          url: (->
            boxHost = @get 'boxHost'
            "http://#{boxHost}:#{port}" if boxHost
          ).property 'boxHost'
  ]

  didClickBetaNotice: ->
    # TODO: beta notice

