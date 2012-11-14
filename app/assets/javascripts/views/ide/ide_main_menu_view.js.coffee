menu = (name, items) -> AIO.Menu.create(name: name, items: items)
menuItem = (name, attrs={}) ->
  attrs.name = name
  AIO.MenuItem.create(attrs)
separator = AIO.MenuItem.create(separator: true)

AIO.IdeMainMenuView = Em.View.extend
  templateName: 'templates/ide/main_menu'
  elementId: 'ide_main_menu_view'
  heightBinding: 'AIO.router.ideLayoutController.mainMenuViewHeight'

  menu: [
    menu 'Action.IO', [
      menuItem 'About Action.IO', callback: ->
        $('#about_actionio').modal 'show'
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
      menuItem 'Close',
        macKey: ['ctrl+w', 'shift+ctrl+w'], pcKey: 'ctrl+alt+w'
        disabledBinding: Em.Binding.oneWay('AIO.router.ideEditorController.hasNoTab')
        callback: (controller) ->
          controller.fileClose()
    ]
    menu 'Navigate', [
      menuItem 'Select Next Tab', macKey: 'shift+ctrl+]', pcKey: 'ctrl+alt+]', callback: (controller) ->
        controller.navigateSelectNextTab()
      menuItem 'Select Previous Tab', macKey: 'shift+ctrl+[', pcKey: 'ctrl+alt+[', callback: (controller) ->
        controller.navigateSelectPreviousTab()
      separator
      menuItem 'Focus Console', macKey: 'shift+ctrl+c', pcKey: 'ctrl+alt+c', callback: (controller) ->
        controller.navigateFocusConsole()
    ]
    menu 'View', [
      menuItem 'Toggle Console Full Screen', macKey: 'shift+ctrl+f', pcKey: 'ctrl+alt+f', callback: ->
        ideConsoleController = AIO.get 'router.ideConsoleController'
        ideConsoleController.toggleProperty 'fullscreen'
    ]
    menu 'Preview',
      _.map([3000, 4000, 8080, 8888], (port) ->
        menuItem "Port #{port}",
          boxHostBinding: Em.Binding.oneWay('AIO.router.ideController.content.boxHost')
          url: (->
            boxHost = @get 'boxHost'
            "http://#{boxHost}:#{port}" if boxHost
          ).property 'boxHost').concat [
        separator
        menuItem 'Preview Help',
          url: 'http://help.action.io/customer/portal/articles/802627-previewing-web-application'
      ]
    menu 'Help', [
      menuItem 'Report an issue...'
        url: 'mailto: support@action.io?subject=Action.IO%20Beta%20Feedback'
      menuItem 'Getting Started',
        url: 'http://help.action.io/'
      menuItem 'Frequently Asked Questions',
        url: 'http://help.action.io/customer/portal/topics/364285-action-web-ide/articles'
    ]
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

  didClickBetaNotice: ->
    @$('#beta_notice').modal 'show'
