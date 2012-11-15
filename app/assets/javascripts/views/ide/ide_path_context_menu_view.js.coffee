AIO.IdePathContextMenuView = Em.View.extend
  templateName: 'templates/ide/path_context_menu'
  elementId: 'ide_path_context_menu_view'
  classNames: ['dropdown']

  path: null

  willDestroyElement: ->
    @_super()
    @set 'path', null

  show: (event, path) ->
    mixpanel?.track 'path_context:show'
    @set 'path', path

    @$('.dropdown-menu').css
      top: event.clientY
      left: event.clientX

    @$().addClass 'open'

  didClickOpen: ->
    mixpanel?.track 'path_context:open'
    path = @get 'path'
    @get('controller').openPath path

  didClickRefresh: ->
    mixpanel?.track 'path_context:refresh'
    path = @get 'path'
    @get('controller').refresh path

  didClickNewFile: ->
    mixpanel?.track 'path_context:new_file'
    path = @get 'path'
    @get('controller').newPath path, false

  didClickNewFolder: ->
    mixpanel?.track 'path_context:new_folder'
    path = @get 'path'
    @get('controller').newPath path, true

  didClickUploadFiles: ->
    mixpanel?.track 'path_context:upload'
    path = @get 'path'
    @get('controller').showUploadDialog path

  didClickSetFolderAsRoot: ->
    mixpanel?.track 'path_context:set_root'
    path = @get 'path'
    @get('controller').setPathAsRoot path
