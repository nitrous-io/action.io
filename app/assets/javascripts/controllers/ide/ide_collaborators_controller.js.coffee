AIO.IdeCollaboratorsController = Em.Controller.extend
  manageCollaboratorsDialog: null

  initialize: ->

  reset: ->
    this.hideManageCollaboratorsDialog()

  showManageCollaboratorsDialog: ->
    @set 'manageCollaboratorsDialog', AIO.ManageCollaboratorsDialog.create()

  hideManageCollaboratorsDialog: ->
    @set 'manageCollaboratorsDialog', null
