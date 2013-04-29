AIO.IdePathView = Em.View.extend
  templateName: 'templates/ide/path'
  tagName: 'li'
  path: null
  classNameBindings: ['path.selected']

  click: (event) ->
    this._selectFile event
    controller = @get 'controller'
    path = @get 'path'
    if path.get 'name'
      controller.openPath path
    sidebarView = this.nearestOfType AIO.IdeSidebarView
    sidebarView.hideContextMenu()

  contextMenu: (event) ->
    this._selectFile event
    path = @get 'path'
    sidebarView = this.nearestOfType AIO.IdeSidebarView
    sidebarView.showContextMenu event, path

  _selectFile: (event) ->
    event.preventDefault()
    event.stopPropagation()
    controller = @get 'controller'
    path = @get 'path'
    if previouslySelectedPath = controller.get 'currentlySelectedPath'
      previouslySelectedPath.set 'selected', false
    if path.get 'file'
      path.set 'selected', true
      controller.set 'currentlySelectedPath', path
