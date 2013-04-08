AIO.IdeConfirmCloseDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/ide/confirm_close_dialog'
  elementId: 'ide_confirm_close_dialog_view'
  contentBinding: 'controller.confirmCloseDialog' # ideEditorController

  didClickSave: ->
    if tab = @get('content.document')
      controller = @get('controller')
      @set 'content', null
      controller.saveDocument tab

  didClickDontSave: ->
    if tab = @get('content.document')
      @set 'content', null
      tab.set 'closedWithoutSaving', true
      @get('controller').removeTab(tab, true)
