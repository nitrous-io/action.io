AIO.IdePathNameView = Em.View.extend
  templateName: 'templates/ide/path_name'
  tagName: 'a'
  classNameBindings: ['path.loading:loading']

  path: null

  click: ->
    path = @get 'path'
    @get('controller').openPath path

  contextMenu: (event) ->
    event.preventDefault()
    event.stopPropagation()
    path = @get 'path'
    sidebarView = this.nearestOfType AIO.IdeSidebarView
    sidebarView.showContextMenu event, path

