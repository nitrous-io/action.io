AIO.IdeMainMenuController = Em.Controller.extend
  initialize: ->

  reset: ->

  fileNew: ->
    if editorController = AIO.get 'router.ideEditorController'
      editorController.createTab()

  fileClose: ->
    if editorController = AIO.get 'router.ideEditorController'
      editorController.removeTab()

