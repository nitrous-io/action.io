AIO.IdeSidebarView = Em.View.extend
  templateName: 'templates/ide/sidebar'
  elementId: 'ide_sidebar_view'

  didClickSetHomeAsRoot: ->
    mixpanel?.track 'sidebar:set_root'
    @get('controller').setHomeAsRoot()

  didClickRefresh: ->
    mixpanel?.track 'sidebar:refresh'
    @get('controller').refreshAll()

  didClickUpload: ->
    mixpanel?.track 'sidebar:upload'
    @get('controller').showUploadDialog()

  didClickShowHidden: ->
    mixpanel?.track 'sidebar:show_hidden'
    @get('controller').toggleProperty 'hiddenFilesVisible'

  didRightClickBackground: (event) ->
    mixpanel?.track 'sidebar:background'
    event.preventDefault()

  showContextMenu: (event, path) ->
    mixpanel?.track 'sidebar:context_menu'
    return if @get 'controller.sftpSocketNotReady'
    contextMenuView = @get 'contextMenuView'
    contextMenuView.show event, path
