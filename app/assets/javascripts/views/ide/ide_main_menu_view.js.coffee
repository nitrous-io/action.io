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
  classNames: ['ide', 'main_menu']

  performMenuAction: (event) ->
    menuItem = event.context
    menuItem.callback?()

  menu: menu('Main Menu', [
    menu 'Action.IO', [
      menuItem 'About Action.IO'
    ]
    menu 'File', [
      menuItem 'New', 'shift+ctrl+n', 'ctrl+n', ->
        console.log 'new'
        #@editor.newDocument()
      menuItem 'Save', ['command+s', 'ctrl+s'], 'ctrl+s', ->
        #@editor.currentTab()?.saveFile()
      separator
      menuItem 'Close', 'ctrl+w', 'ctrl+w', ->
        #if currentTab = @editor.currentTab()
          #@editor.closeTab(currentTab)
    ]
    menu 'Edit', [
      menuItem 'Coming Soon'
    ]
    menu 'Collaborate', [
      menuItem 'Coming Soon'
    ]
    menu 'Preview', [
      menuItem 'localhost:3000', null, null, 'TODO' + ':3000/'
      menuItem 'localhost:4000', null, null, 'TODO' + ':4000/'
    ]
    menu 'Deploy', [
      menuItem 'Coming Soon'
    ]
    menu 'Help', [
      menuItem 'Coming Soon'
    ]
  ])

