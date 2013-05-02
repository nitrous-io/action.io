AIO.IdeManageCollaboratorsDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/ide/manage_collaborators_dialog'
  elementId: 'ide_manage_collaborators_dialog_view'
  contentBinding: 'controller.manageCollaboratorsDialog' # controller = ideCollaborationController

  viewDidAppear: ->
    @_super()
    @get('content').fetch()

  viewDidDisappear: ->

  didClickDone: ->
    @get('controller').hideManageCollaboratorsDialog()

  didClickAdd: ->
    @get('content').addCollaborator =>
      @$('.ide_manage_collaborators_dialog_text_field').focus()

  didClickRemove: (event) ->
    collaborator = event.context
    @get('content').removeCollaborator collaborator

AIO.IdeManageCollaboratorsDialogTextField = Em.TextField.extend
  classNames: ['ide_manage_collaborators_dialog_text_field']

  insertNewline: ->
    @get('parentView').didClickAdd()

