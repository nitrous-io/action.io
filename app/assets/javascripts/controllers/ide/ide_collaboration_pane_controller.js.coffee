AIO.IdeCollaborationPaneController = Em.Controller.extend
  manageCollaboratorsDialog: null
  firebaseAuthenticated: false
  firebase: null         # <host>
  firebaseUsers: null    # <host>/box/:box_id/users
  firebasePresence: null # <host>/box/:box_id/users/:username
  firebaseChat: null     # <host>/box/:box_id/chat
  users: null            # array of users
  messages: null         # chat messages

  initialize: ->
    this._initFirebase()
    @set 'users', []
    @set 'messages', []

  reset: ->
    this.hideManageCollaboratorsDialog()
    this._resetFirebase()
    @set 'users', null
    @set 'messages', null

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
            this._initFirebaseUsers()
            this._initFirebasePresence()
            this._initFirebaseChat()

  _resetFirebase: ->
    this._resetFirebaseUsers()
    this._resetFirebasePresence()
    this._resetFirebaseChat()
    @set 'firebaseAuthenticated', false
    @get('firebase')?.unauth()

  _initFirebaseUsers: ->
    boxId = AIO.get 'router.ideController.content.id'
    firebaseUsersURL = "#{AIO.get 'firebaseHost'}/box/#{boxId}/users"
    firebaseUsers = new Firebase firebaseUsersURL
    firebaseUsers.on 'child_added', (child) =>
      @get('users')?.addObject child.name()
    firebaseUsers.on 'child_removed', (child) =>
      @get('users')?.removeObject child.name()
    @set 'firebaseUsers', firebaseUsers

  _resetFirebaseUsers: ->
    @get('firebaseUsers')?.off()
    @set 'firebaseUsers', null

  _initFirebasePresence: ->
    boxId = AIO.get 'router.ideController.content.id'
    username = AIO.get 'router.applicationController.currentUser.username'
    firebaseUserURL = "#{AIO.get 'firebaseHost'}/box/#{boxId}/users/#{username}"
    firebaseUser = new Firebase firebaseUserURL
    firebasePresence = firebaseUser.push()
    firebasePresence.onDisconnect().remove()
    firebasePresence.set true
    @set 'firebasePresence', firebasePresence

  _resetFirebasePresence: ->
    @get('firebasePresence')?.remove()
    @set 'firebasePresence', null

  _initFirebaseChat: ->
    boxId = AIO.get 'router.ideController.content.id'
    firebaseChatURL = "#{AIO.get 'firebaseHost'}/box/#{boxId}/chat"
    firebaseChat = new Firebase firebaseChatURL
    firebaseChat.endAt().limit(100).on 'child_added', (child) =>
      values = child.val()
      message = AIO.ChatMessage.create username: values[0], message: values[1]
      @get('messages')?.addObject message
    @set 'firebaseChat', firebaseChat

  _resetFirebaseChat: ->
    @get('firebaseChat')?.off()
    @set 'firebaseChat', null

  sendChatMessage: (message) ->
    message = message?.trim()
    firebaseChat = @get 'firebaseChat'
    username = AIO.get 'router.applicationController.currentUser.username'
    if firebaseChat && username && message
      firebaseChat.push [username, message]
      AIO.util.mixpanelIncrement 'ide_send_chat_message'

  sendEventNotification: (message) ->
    message = message?.trim()
    firebaseChat = @get 'firebaseChat'
    if firebaseChat && message
      firebaseChat.push [null, message]
      AIO.util.mixpanelIncrement 'ide_send_event_notification'
