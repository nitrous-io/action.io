AIO.IdeCollaborationController = Em.Controller.extend
  manageCollaboratorsDialog: null
  firebase: null
  firebaseAuthenticated: false

  initialize: ->
    this._initFirebase()

  reset: ->
    this.hideManageCollaboratorsDialog()
    this._resetFirebase()

  showManageCollaboratorsDialog: ->
    @set 'manageCollaboratorsDialog', AIO.ManageCollaboratorsDialog.create()

  hideManageCollaboratorsDialog: ->
    @set 'manageCollaboratorsDialog', null

  _initFirebase: ->
    firebase = @get('firebase') || new Firebase AIO.get('firebaseHost')
    @set 'firebase', firebase

    boxId = AIO.get 'router.ideController.content.id'

    $.get('/firebase/auth_token', box_id: boxId).done (data) =>
      if data.auth_token?
        firebase.auth data.auth_token, (error) =>
          unless error
            @set 'firebaseAuthenticated', true

  _resetFirebase: ->
    @get('firebase')?.unauth()
    @set 'firebaseAuthenticated', false
