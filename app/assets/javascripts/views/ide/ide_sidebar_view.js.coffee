AIO.IdeSidebarView = Em.View.extend
  templateName: 'templates/ide/sidebar'
  elementId: 'ide_sidebar_view'

  didClickSetHomeAsRoot: ->
    @get('controller').setHomeAsRoot()

  didClickRefresh: ->
    @get('controller').refreshAll()

  didClickUpload: ->
    # TODO: file upload

  didClickShowHidden: ->
    # TODO: show hidden files

  didRightClickBackground: (event) ->
    event.preventDefault()

  showContextMenu: (event, path) ->
    contextMenuView = @get 'contextMenuView'
    contextMenuView.show event, path

