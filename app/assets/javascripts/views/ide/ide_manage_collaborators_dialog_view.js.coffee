AIO.IdeManageCollaboratorsDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/ide/manage_collaborators_dialog'
  elementId: 'ide_manage_collaborators_dialog_view'
  contentBinding: 'controller.manageCollaboratorsDialog' # controller = ideCollaboratorsController

  viewDidAppear: ->
    @_super()
    @get('content').fetch()

  viewDidDisappear: ->

  didClickDone: ->
    @get('controller').hideManageCollaboratorsDialog()

  didClickAdd: ->
    @get('content').addCollaborator()

  didClickRemove: (event) ->
    collaborator = event.context
    @get('content').removeCollaborator collaborator

