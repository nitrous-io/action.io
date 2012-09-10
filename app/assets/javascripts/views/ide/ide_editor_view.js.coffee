AIO.IdeEditorView = AIO.IdeTabView.extend
  templateName: 'templates/ide/editor'
  elementId: 'ide_editor_view'
  modelClass: AIO.Document
  tabsBinding: 'AIO.router.ideController.documents'

