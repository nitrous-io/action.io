AIO.IdeCollaboratorsController = Em.Controller.extend
  needs: ['ide', 'ideLayout', 'ideMainMenu', 'ideSidebar', 'ideEditor', 'ideConsole', 'ideCollaborators', 'application']
  manageCollaboratorsDialog: null

  initialize: ->

  reset: ->
    this.hideManageCollaboratorsDialog()

  showManageCollaboratorsDialog: ->
    @set 'manageCollaboratorsDialog', AIO.ManageCollaboratorsDialog.create()

  hideManageCollaboratorsDialog: ->
    @set 'manageCollaboratorsDialog', null
