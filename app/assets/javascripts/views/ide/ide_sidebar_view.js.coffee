AIO.IdeSidebarView = Em.View.extend
  templateName: 'templates/ide/sidebar'
  elementId: 'ide_sidebar_view'

  didClickChangeRoot: ->
    # TODO: change tree root

  didClickRefresh: ->
    @get('controller').refreshAll()

  didClickUpload: ->
    # TODO: file upload

  didClickShowHidden: ->
    # TODO: show hidden files

