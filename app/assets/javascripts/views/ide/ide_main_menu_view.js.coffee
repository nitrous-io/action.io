menu = (name, items) -> AIO.Menu.create(name: name, items: items)
menuItem = (name, macKey, pcKey, action) ->
  attrs = { name: name, macKey: macKey, pcKey: pcKey }
  if _.isFunction(action)
    attrs.callback = action
  else if _.isString(action)
    attrs.url = action
  AIO.MenuItem.create(attrs)
separator = AIO.MenuItem.create(separator: true)

AIO.IdeMainMenuView = Em.View.extend
  templateName: 'templates/ide/main_menu'
  elementId: 'ide_main_menu_view'

  didClickMenuItem: (event) ->
    menuItem = event.context
    menuItem.callback? @get('controller')

  menu: [
    menu 'Action.IO', [
      menuItem 'About Action.IO'
    ]
    menu 'File', [
      menuItem 'New', 'shift+ctrl+n', 'ctrl+n', (controller) ->
        controller.fileNew()
      menuItem 'Save', ['command+s', 'ctrl+s'], 'ctrl+s', (controller) ->
        # TODO: implement save file
      separator
      menuItem 'Close', 'ctrl+w', 'ctrl+w', (controller) ->
        controller.fileClose()
    ]
    menu 'Preview', [
      menuItem 'localhost:3000', null, null, 'TODO' + ':3000/'
      menuItem 'localhost:4000', null, null, 'TODO' + ':4000/'
    ]
  ]

  didClickBetaNotice: ->
    # TODO: beta notice

