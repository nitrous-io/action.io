menu = (name, items) -> AIO.Menu.create(name: name, items: items)
menuItem = (name, attrs={}) ->
  attrs.name = name
  AIO.MenuItem.createWithMixins(attrs)
separator = AIO.MenuItem.create(separator: true)

previewMenu = menu 'Preview',
  [ menuItem 'Port 80 → 3000',
      boxBinding: Em.Binding.oneWay('AIO.router.ideController.content')
      target: '_blank'
      url: (->
        "http://#{@get 'box.boxHost'}"
      ).property 'box.boxHost'
  ]
  [ menuItem 'Port 443 → 3000 (SSL)',
      boxBinding: Em.Binding.oneWay('AIO.router.ideController.content')
      target: '_blank'
      hide: (->
        !@get('box.region.ssl_enabled') # FIXME Use Em.Binding.not() when we upgrade Ember.
      ).property 'box.region.ssl_enabled'
      url: (->
        "https://#{@get 'box.boxHost'}"
      ).property 'box.boxHost'
  ].concat _.map([4000, 8080, 8888], (port) ->
    menuItem "Port #{port}",
      boxHostBinding: Em.Binding.oneWay('AIO.router.ideController.content.boxHost')
      target: '_blank'
      url: (->
        if boxHost = @get 'boxHost'
          if port == 3000
            "http://#{boxHost}"
          else
            "http://#{boxHost}:#{port}"
      ).property 'boxHost').concat [
    separator
    menuItem 'Set Password...',
      disabledBinding: Em.Binding.oneWay('AIO.router.ideController.content.notOwnBox')
      callback: (controller) ->
        controller.manageBasicAuth()
    separator
    menuItem 'Preview Help',
      url: 'http://help.nitrous.io/categories/previewing/'
      target: '_blank'
  ]

helpMenu = menu 'Help', [
  menuItem 'Help Center',
    url: 'http://help.nitrous.io/'
    target: '_blank'
  menuItem 'Web IDE Overview',
    url: 'http://help.nitrous.io/ide-general'
    target: '_blank'
  menuItem 'Frequently Asked Questions',
    url: 'http://help.nitrous.io/categories/faq'
    target: '_blank'
  separator
  menuItem 'Blog',
    url: 'http://blog.nitrous.io/'
    target: '_blank'
  menuItem 'Updates',
    url: 'http://updates.nitrous.io/'
    target: '_blank'
  separator
  menuItem 'Report an Issue...',
    url: 'mailto:support@nitrous.io?subject=Nitrous.IO%20Beta%20Feedback'
    target: '_blank'
]

AIO.IdeMainMenuView = Em.View.extend
  templateName: 'templates/ide/main_menu'
  elementId: 'ide_main_menu_view'
  heightBinding: 'AIO.router.ideLayoutController.mainMenuViewHeight'
  hideMainMenu: false

  noSecondaryMenuBinding: Em.Binding.oneWay 'AIO.isChromeWebView'

  menu: [
    menu 'Nitrous.IO', [
      menuItem 'About Nitrous.IO', callback: ->
        $('#about_nitrousio').modal 'show'
    ]
    menu 'File', [
      menuItem 'New', macKey: 'shift+ctrl+n', pcKey: 'ctrl+alt+n', callback: (controller) ->
        controller.fileNew()
      menuItem 'Save',
        macKey: ['command+s', 'ctrl+s', 'shift+ctrl+s'], pcKey: ['ctrl+s', 'ctrl+alt+s']
        disabledBinding: Em.Binding.oneWay('AIO.router.ideEditorController.hasNoTab')
        callback: (controller) ->
          controller.fileSave()
      separator
      menuItem 'Refresh Tree',
        macKey: ['shift+ctrl+r'], pcKey: ['ctrl+alt+r']
        disabledBinding: Em.Binding.oneWay('AIO.router.ideSidebarController.sftpSocketNotReady')
        callback: (controller) ->
          controller.fileRefreshTree()
      separator
      menuItem 'Close',
        macKey: ['shift+ctrl+w', 'ctrl+w'], pcKey: 'ctrl+alt+w'
        disabledBinding: Em.Binding.oneWay('AIO.router.ideEditorController.hasNoTab')
        callback: (controller) ->
          controller.fileClose()
    ]
    menu 'Edit', [
      menuItem 'Find',
        macKey: ['command+f'], pcKey: ['ctrl+f']
        disabledBinding: Em.Binding.oneWay('AIO.router.ideEditorController.hasNoTab')
        callback: (controller) ->
          controller.editFind()
      menuItem 'Find Next',
        macKey: ['command+g'], pcKey: ['ctrl+g']
        disabledBinding: Em.Binding.oneWay('AIO.router.ideEditorController.hasNoTab')
        callback: (controller) ->
          controller.editFindNext()
      menuItem 'Find Previous',
        macKey: ['shift+command+g'], pcKey: ['shift+ctrl+g']
        disabledBinding: Em.Binding.oneWay('AIO.router.ideEditorController.hasNoTab')
        callback: (controller) ->
          controller.editFindPrevious()
      separator
      menuItem 'Replace',
        macKey: ['command+option+f'], pcKey: ['shift+ctrl+f']
        disabledBinding: Em.Binding.oneWay('AIO.router.ideEditorController.hasNoTab')
        callback: (controller) ->
          controller.editReplace()
      menuItem 'Replace All',
        macKey: ['shift+command+option+f'], pcKey: ['shift+ctrl+r']
        disabledBinding: Em.Binding.oneWay('AIO.router.ideEditorController.hasNoTab')
        callback: (controller) ->
          controller.editReplaceAll()
    ]
    menu 'View', [
      menuItem 'Select Next Tab', macKey: 'shift+ctrl+]', pcKey: 'shift+ctrl+]', callback: (controller) ->
        controller.viewSelectNextTab()
      menuItem 'Select Previous Tab', macKey: 'shift+ctrl+[', pcKey: 'shift+ctrl+[', callback: (controller) ->
        controller.viewSelectPreviousTab()
      separator
      menuItem 'Focus Console', macKey: 'shift+ctrl+c', pcKey: 'ctrl+alt+c', callback: (controller) ->
        controller.viewFocusConsole()
      menuItem 'Toggle Full Screen Console', macKey: 'shift+ctrl+f', pcKey: 'ctrl+alt+f', callback: (controller) ->
        controller.viewToggleFullScreenConsole()
      menuItem 'Toggle Full Screen Editor', macKey: 'shift+ctrl+e', pcKey: 'ctrl+alt+e', callback: (controller) ->
        controller.viewToggleFullScreenEditor()
    ]
    menu 'Collaborate', [
      menuItem 'Manage Collaborators...',
        disabledBinding: Em.Binding.oneWay('AIO.router.ideController.content.notOwnBox')
        callback: (controller) ->
          controller.collaborateManageCollaborators()
      separator
      menuItem 'Toggle Chat', callback: (controller) ->
        controller.collaborateToggleChat()
    ]
    menu 'Autoparts', [
      menuItem 'Install Parts...',
        callback: (controller) ->
          controller.autopartsInstall()
      menuItem 'Uninstall Parts...',
        disabledBinding: Em.Binding.oneWay('AIO.router.ideAutopartsController.noPartsInstalled')
        callback: (controller) ->
          controller.autopartsUninstall()
      menuItem 'Start/Stop Parts...',
        disabledBinding: Em.Binding.oneWay('AIO.router.ideAutopartsController.noPartsStatuses')
        callback: (controller) ->
          controller.autopartsServices()
      separator
      menuItem 'Autoparts Help',
        url: 'http://help.nitrous.io/autoparts/'
        target: '_blank'
    ]
    previewMenu
    helpMenu
  ]

  altMenu: [
    previewMenu,
    helpMenu
  ]

  didInsertElement: ->
    @_super()
    $(window).bind 'resize.ideMainMenuView', _.bind(@onResize, this)
    this.onResize()

  willDestroyElement: ->
    @_super()
    $(window).unbind 'resize.ideMainMenuView'

  onResize: ->
    @set 'height', @$().outerHeight()
