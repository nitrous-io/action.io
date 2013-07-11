AIO.IdeCollaborationPaneController = Em.Controller.extend
  manageCollaboratorsDialog: null
  firebaseAuthenticated: false
  firebase: null                # <host>
  firebaseUsers: null           # <host>/box/:box_id/users
  firebasePresence: null        # <host>/box/:box_id/users/:username
  firebaseChat: null            # <host>/box/:box_id/chat
  users: null                   # array of users
  messages: null                # chat messages
  userColor: null               # color of current user

  initialize: ->
    this._initFirebase()
    @set 'users', []
    @set 'messages', []

  reset: ->
    this.hideManageCollaboratorsDialog()
    this._resetFirebase()
    @set 'users', null
    @set 'messages', null
    @set 'userColor', null

  showManageCollaboratorsDialog: ->
    @set 'manageCollaboratorsDialog', AIO.ManageCollaboratorsDialog.create()

  hideManageCollaboratorsDialog: ->
    @set 'manageCollaboratorsDialog', null

  sendMessage: (message, messageType) ->
    message = message?.trim()
    firebaseChat = @get 'firebaseChat'
    username = AIO.get 'currentUser.username'
    if firebaseChat && username && message && messageType
      firebaseChat.push [username, message, messageType]
      AIO.util.mixpanelIncrement 'ide_send_event_notification'

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
            this._setUserColor =>
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
    firebaseUsers.on 'child_added', (userObj) =>
      color = userObj.child('color').val()
      name = userObj.child('name').val()
      @get('users')?.addObject AIO.CollabSessionUser.create name: name, color: color
    firebaseUsers.on 'child_removed', (userObj) =>
      name = userObj.child('name').val()
      if users = @get('users')
        removed_user = users.find (user) ->
          user.get('name') == name
        users.removeObject removed_user
    @set 'firebaseUsers', firebaseUsers

  _resetFirebaseUsers: ->
    @get('firebaseUsers')?.off()
    @set 'firebaseUsers', null

  _setUserColor: (callback) ->
    boxId = AIO.get 'router.ideController.content.id'
    firebaseUserColorIdURL = "#{AIO.get 'firebaseHost'}/box/#{boxId}/next_user_color_id"
    firebaseUserColorId = new Firebase firebaseUserColorIdURL
    firebaseUserColorId.once 'value', (userColorIdSnapshot) =>
      userColorId = (userColorIdSnapshot.val() ? 0)
      color = AIO.UserColors[userColorId % AIO.UserColors.length]
      @set 'userColor', color
      firebaseUserColorId.set (userColorId + 1)
      callback()

  _initFirebasePresence: ->
    boxId = AIO.get 'router.ideController.content.id'
    username = AIO.get 'currentUser.username'
    usercolor = @get 'userColor'
    firebaseUserURL = "#{AIO.get 'firebaseHost'}/box/#{boxId}/users/#{username}"
    firebaseUser = new Firebase firebaseUserURL
    firebasePresence = firebaseUser.push()
    firebasePresence.onDisconnect().remove()
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
      message = AIO.CollabMessage.create username: values[0], data: values[1], type: values[2]
      @get('messages')?.addObject message
    @set 'firebaseChat', firebaseChat

  _resetFirebaseChat: ->
    @get('firebaseChat')?.off()
    @set 'firebaseChat', null
