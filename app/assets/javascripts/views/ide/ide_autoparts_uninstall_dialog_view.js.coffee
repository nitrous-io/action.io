AIO.IdeAutopartsUninstallDialogView = AIO.IdeAutopartsCommonDialogView.extend
  elementId: 'ide_autoparts_uninstall_dialog_view'
  contentBinding: 'controller.autopartsUninstallDialog' # controller = ideAutopartsController

  dialogTitle: 'Uninstall Parts'
  filterPlaceholder: 'Filter installed parts'

  filter: (matchingParts) ->
    matchingParts.filterProperty('installed')

  loadParts: (callback) ->
    @get('controller').installed callback

  didClickAutopartsInstall: ->
    this.hide()
    AIO.get('router.ideAutopartsController').showAutopartsInstallDialog()
