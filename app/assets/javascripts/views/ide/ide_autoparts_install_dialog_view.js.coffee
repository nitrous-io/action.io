AIO.IdeAutopartsInstallDialogView = AIO.IdeAutopartsCommonDialogView.extend
  elementId: 'ide_autoparts_install_dialog_view'
  contentBinding: 'controller.autopartsInstallDialog' # controller = ideAutopartsController

  dialogTitle: 'Install Parts'
  filterPlaceholder: 'Filter available parts'

  filter: (matchingParts) ->
    matchingParts.rejectProperty('installed')

  loadParts: (callback) ->
    @get('controller').available callback
