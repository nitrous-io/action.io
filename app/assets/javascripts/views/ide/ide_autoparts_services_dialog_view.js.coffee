AIO.IdeAutopartsServicesDialogView = AIO.IdeAutopartsCommonDialogView.extend
  elementId: 'ide_autoparts_services_dialog_view'
  contentBinding: 'controller.autopartsServicesDialog' # controller = ideAutopartsController

  servicesView: true

  dialogTitle: 'Start/Stop Parts'
  filterPlaceholder: 'Filter Parts'

  filter: (matchingParts) ->
    matchingParts.filterProperty('status')

  loadParts: (callback) ->
    @get('controller').hasStatus callback
