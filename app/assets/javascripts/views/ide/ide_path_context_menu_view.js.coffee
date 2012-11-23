AIO.IdePathContextMenuView = Em.View.extend
  templateName: 'templates/ide/path_context_menu'
  elementId: 'ide_path_context_menu_view'
  classNames: ['dropdown']

  path: null

  willDestroyElement: ->
    @_super()
    @set 'path', null

  show: (event, path) ->
    @set 'path', path

    @$('.dropdown-menu').css
      top: event.clientY
      left: event.clientX

    @$().addClass 'open'

  didClickOpen: ->
    path = @get 'path'
    @get('controller').openPath path

  didClickRefresh: ->
    path = @get 'path'
    @get('controller').refresh path

  didClickNewFile: ->
    path = @get 'path'
    @get('controller').newPath path, false

  didClickNewFolder: ->
    path = @get 'path'
    @get('controller').newPath path, true

  didClickUploadFiles: ->
    path = @get 'path'
    @get('controller').showUploadDialog path

  didClickSetFolderAsRoot: ->
    path = @get 'path'
    @get('controller').setPathAsRoot path

  didClickDelete: ->
    path = @get 'path'
    type = if path.get("directory") then "directory" else "file"
    willDelete = window.confirm "Do you want to delete #{type}: #{path.get("absolutePath")}"
    @get('controller').delete path if willDelete
