AIO.IdeEditorView = Em.View.extend AIO.IdeTabViewMixin,
  templateName: 'templates/ide/editor'
  elementId: 'ide_editor_view'

  showSaveDialog: (document) ->
    @set 'controller.saveDialog.document', document
    @get('saveDialogView').show()

