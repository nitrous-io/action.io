AIO.IdeAutopartsRemoveDialogView = AIO.IdeAutopartsCommonDialogView.extend
  elementId: 'ide_autoparts_remove_dialog_view'
  contentBinding: 'controller.autopartsRemoveDialog' # controller = ideAutopartsController

  dialogTitle: 'Remove Autoparts'
  filterPlaceholder: 'Filter installed packages'

  filter: (matchingParts) ->
    matchingParts.filterProperty('installed')

  loadParts: (callback) ->
    @get('controller').installed callback

  didClickAutopartsInstall: ->
    this.hide()
    AIO.get('router.ideAutopartsController').showAutopartsInstallDialog()
