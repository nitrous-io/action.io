AIO.IdeSidebarView = Em.View.extend
  templateName: 'templates/ide/sidebar'
  elementId: 'ide_sidebar_view'

  didClickSetHomeAsRoot: ->
    @get('controller').setHomeAsRoot()

  didClickRefresh: ->
    @get('controller').refreshAll()

  didClickUpload: ->
    @get('controller').showUploadDialog()

  didClickShowHidden: ->
    @get('controller').toggleProperty 'hiddenFilesVisible'

  didRightClickBackground: (event) ->
    event.preventDefault()

  showContextMenu: (event, path) ->
    return if @get 'controller.sftpSocketNotReady'
    contextMenuView = @get 'contextMenuView'
    contextMenuView.show event, path

