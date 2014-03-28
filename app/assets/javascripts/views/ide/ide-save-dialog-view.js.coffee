AIO.IdeSaveDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/ide/save_dialog'
  elementId: 'ide_save_dialog_view'
  contentBinding: 'controller.saveDialog' # ideEditorController

  viewDidAppear: ->
    @$('#save_path').focus()

  didClickSave: ->
    @get('controller').saveNewDocument()

AIO.IdeSaveDialogTextField = Em.TextField.extend
  insertNewline: ->
    @get('parentView').didClickSave()

