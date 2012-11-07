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
        macKey: ['command+s', 'ctrl+s'], pcKey:'ctrl+s'
        disabledBinding: Em.Binding.oneWay('AIO.router.ideEditorController.hasNoTab')
        callback: (controller) ->
          controller.fileSave()
      separator
      menuItem 'Close',
        macKey: 'ctrl+w', pcKey: 'ctrl+alt+w'
        disabledBinding: Em.Binding.oneWay('AIO.router.ideEditorController.hasNoTab')
        callback: (controller) ->
          controller.fileClose()
    ]
    menu 'Navigate', [
      menuItem 'Focus Console', macKey: 'shift+ctrl+c', pcKey: 'ctrl+alt+c', callback: (controller) ->
        controller.navigateActivateConsole()

      menuItem 'Cycle Tab', macKey: 'shift+ctrl+x', pcKey: 'ctrl+alt+x', callback: (controller) ->
        controller.cycleActiveTab()
    ]
    menu 'Preview',
      _.map [3000, 4000, 8080, 8888], (port) ->
        menuItem "Port #{port}",
          boxHostBinding: Em.Binding.oneWay('AIO.router.ideController.content.boxHost')
          url: (->
            boxHost = @get 'boxHost'
            "http://#{boxHost}:#{port}" if boxHost
          ).property 'boxHost'
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
