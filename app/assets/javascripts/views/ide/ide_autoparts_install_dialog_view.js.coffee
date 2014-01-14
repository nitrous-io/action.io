AIO.IdeAutopartsInstallDialogView = AIO.IdeAutopartsCommonDialogView.extend
  elementId: 'ide_autoparts_install_dialog_view'
  contentBinding: 'controller.autopartsInstallDialog' # controller = ideAutopartsController

  dialogTitle: 'Install Autoparts'
  filterPlaceholder: 'Filter available packages'

  filter: (matchingParts) ->
    matchingParts.rejectProperty('installed')

  loadParts: (callback) ->
    @get('controller').available callback
