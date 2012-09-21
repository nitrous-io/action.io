AIO.IdeSaveDialogView = Em.View.extend AIO.Validatable,
  templateName: 'templates/ide/save_dialog'
  elementId: 'ide_save_dialog_view'
  contentBinding: 'controller.saveDialog'

  showOrHide: (->
    if @get 'controller.saveDialog.visible'
      this.show()
    else
      this.hide()
  ).observes 'controller.saveDialog.visible'

  show: ->
    @$('#save_dialog').modal 'show'
    window.setTimeout =>
      @$('#save_path').focus()
    , 300

  hide: ->
    @$('#save_dialog').modal 'hide'
    @set 'controller.saveDialog', null

  didClickCancel: ->
    @set 'controller.saveDialog.visible', false

  didClickSave: ->
    @get('controller').saveNewDocument()

AIO.IdeSaveDialogTextField = Em.TextField.extend
  insertNewline: ->
    @get('parentView').didClickSave()

