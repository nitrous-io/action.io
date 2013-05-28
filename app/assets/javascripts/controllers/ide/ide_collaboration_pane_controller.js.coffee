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
  firebaseUserCount: null       # number of users present in firebase
  usedUserColors: null          # array of used user colors
  availableUserColors: null

  initialize: ->
    this._initFirebase()
    @set 'users', []
    @set 'messages', []
    @set 'usedUserColors', []
    @set 'availableUserColors', AIO.UserColors

  reset: ->
    this.hideManageCollaboratorsDialog()
    this._resetFirebase()
    @set 'users', null
    @set 'messages', null
    @set 'usedUserColors', null
    @set 'userColor', null
    @set 'availableUserColors', null

  showManageCollaboratorsDialog: ->
    @set 'manageCollaboratorsDialog', AIO.ManageCollaboratorsDialog.create()

  hideManageCollaboratorsDialog: ->
    @set 'manageCollaboratorsDialog', null

  sendMessage: (message, messageType) ->
    message = message?.trim()
    firebaseChat = @get 'firebaseChat'
    username = AIO.get 'router.applicationController.currentUser.username'
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
    firebaseUsers.once 'value', (usersSnapshot) =>
      @set 'firebaseUserCount', usersSnapshot.numChildren()
    firebaseUsers.on 'child_added', (child) =>
      child.forEach (userObj) =>
        color = userObj.child('color').val()
        @get('usedUserColors')?.addObject color
        @get('users')?.addObject AIO.CollabSessionUser.create name: child.name(), color: color
    firebaseUsers.on 'child_removed', (child) =>
      name = child.name()
      if users = @get('users')
        removed_user = users.find (user) ->
          user.get('name') == name
        users.removeObject removed_user
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
    @set 'firebasePresence', firebasePresence

  _resetFirebasePresence: ->
    @get('firebasePresence')?.remove()
    @set 'firebasePresence', null

  _setUserColor: ->
    color = this._nextAvailableUserColor()
    if firebasePresence = @get 'firebasePresence'
      firebasePresence.set color: color
    @set 'userColor', color

  _nextAvailableUserColor: ->
    availableUserColors = @get 'availableUserColors'
    usedUserColors = @get('usedUserColors').toArray()
    if usedUserColors.length < availableUserColors.length
      currentlyAvailableUserColors = _.difference(availableUserColors, usedUserColors)
    else
      availableUserColorsLength = availableUserColors.length
      startingIndex = availableUserColorsLength * Math.round(usedUserColors.length / availableUserColorsLength)
      colorsUsedInCurrentIteration = usedUserColors.slice startingIndex
      currentlyAvailableUserColors = _.difference(availableUserColors, colorsUsedInCurrentIteration)
    currentlyAvailableUserColors.shift()

  _setUserColorAfterLoadingUsedColors: (->
    firebaseUserCount = @get 'firebaseUserCount'
    userColorsLoaded = @get('usedUserColors')?.get 'length'

    if userColorsLoaded? && firebaseUserCount? && (userColorsLoaded == firebaseUserCount)
      this._setUserColor()
  ).observes 'usedUserColors', 'firebaseUserCount'

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
