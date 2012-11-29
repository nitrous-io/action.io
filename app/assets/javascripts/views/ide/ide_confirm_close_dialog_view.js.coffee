AIO.IdeConfirmCloseDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/ide/confirm_close_dialog'
  elementId: 'ide_confirm_close_dialog_view'
  contentBinding: 'controller.confirmCloseDialog' # ideEditorController

  didClickSave: ->
    controller = @get('controller')
    @set 'content', null
    controller.saveDocument controller.get('activeTab')

  didClickDontSave: ->
    @set 'content', null
    @get('controller').removeTab(null, true)


