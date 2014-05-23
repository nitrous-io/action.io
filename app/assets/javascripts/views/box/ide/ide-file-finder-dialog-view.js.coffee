App.IdeFileFinderDialogView = App.IdeModalDialogView.extend
  templateName: 'templates/box/ide/file-finder-dialog'
  elementId: 'ide_file_finder_dialog_view'
  contentBinding: 'controller.fileFinderDialog'

  viewDidAppear: ->
    @_super()
    @$('#file_finder_pattern').focus()

  keyPress: (e) ->
    if e.which == 13
      this.submit()
      return false

  submit: ->
    @get('controller').startFind @get('content.pattern'), @get('content.location')
