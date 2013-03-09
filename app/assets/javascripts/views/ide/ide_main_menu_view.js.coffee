menu = (name, items) -> AIO.Menu.create(name: name, items: items)
menuItem = (name, attrs={}) ->
  attrs.name = name
  AIO.MenuItem.createWithMixins(attrs)
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
    menu 'View', [
      menuItem 'Select Next Tab', macKey: 'shift+ctrl+]', pcKey: 'ctrl+alt+]', callback: (controller) ->
        controller.viewSelectNextTab()
      menuItem 'Select Previous Tab', macKey: 'shift+ctrl+[', pcKey: 'ctrl+alt+[', callback: (controller) ->
        controller.viewSelectPreviousTab()
      separator
      menuItem 'Focus Console', macKey: 'shift+ctrl+c', pcKey: 'ctrl+alt+c', callback: (controller) ->
        controller.viewFocusConsole()
      menuItem 'Toggle Full Screen Console', macKey: 'shift+ctrl+f', pcKey: 'ctrl+alt+f', callback: (controller) ->
        controller.viewToggleFullScreenConsole()
    ]
    menu 'Connect', [
      menuItem 'MongoDB (MongoLab) ...'
        url: 'http://help.action.io/customer/portal/articles/1007291-mongodb-integration-mongolab-'
        target: '_blank'
      menuItem 'PostgreSQL (Heroku) ...'
        url: 'http://help.action.io/customer/portal/articles/991662-integrating-heroku-postgres-with-action-io'
        target: '_blank'
    ]
    menu 'Preview',
      _.map([3000, 4000, 8080, 8888], (port) ->
        menuItem "Port #{port}",
          boxHostBinding: Em.Binding.oneWay('AIO.router.ideController.content.boxHost')
          target: '_blank'
          url: (->
            boxHost = @get 'boxHost'
            "http://#{boxHost}:#{port}" if boxHost
          ).property 'boxHost').concat [
        separator
        menuItem 'Preview Help',
          url: 'http://help.action.io/customer/portal/articles/802627-previewing-web-application'
          target: '_blank'
      ]
    menu 'Help', [
      menuItem 'Report an issue...'
        url: 'mailto:support@action.io?subject=Action.IO%20Beta%20Feedback'
        target: '_blank'
      menuItem 'Getting Started',
        url: 'http://help.action.io/'
        target: '_blank'
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
