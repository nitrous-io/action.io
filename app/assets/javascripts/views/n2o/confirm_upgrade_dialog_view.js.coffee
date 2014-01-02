AIO.ConfirmUpgradeDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/n2o/confirm_upgrade_dialog'
  elementId: 'confirm_upgrade_dialog_view'
  contentBinding: 'controller.confirmUpgradeDialog' # N2oUpgradeController

  init: ->
    @_super()
    @set 'data-keyboard', 'false'

  formattedTotal: (->
    if total = @get('content.total')
      "$#{total.toFixed(2)}"
  ).property 'content.total'

  didClickCancel: ->
    @get('controller').upgradeCanceled()
    @_super()

  didClickConfirm: ->
    @get('controller').upgradeConfirmed()
    this.hide()
