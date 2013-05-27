AIO.IdeCollaborationPaneController = Em.Controller.extend
  manageCollaboratorsDialog: null
  firebaseAuthenticated: false
  firebase: null         # <host>
  firebaseUsers: null    # <host>/box/:box_id/users
  firebasePresence: null # <host>/box/:box_id/users/:username
  firebaseChat: null     # <host>/box/:box_id/chat
  users: null            # array of users
  messages: null         # chat messages
  availableUserColors: [ '#fff', '#00ffff', '#ff0000' ]
  usedUserColors: null
  userColor: null
  firebaseUserCount: null

  initialize: ->
    this._initFirebase()
    @set 'users', []
    @set 'messages', []
    @set 'usedUserColors', []

  reset: ->
    this.hideManageCollaboratorsDialog()
    this._resetFirebase()
    @set 'users', null
    @set 'messages', null
    @set 'usedUserColors', null

  showManageCollaboratorsDialog: ->
    box = AIO.get 'router.ideController.content'
    if box.get('ownBox')
      @set 'manageCollaboratorsDialog', AIO.ManageCollaboratorsDialog.create()

  hideManageCollaboratorsDialog: ->
    @set 'manageCollaboratorsDialog', null

  sendMessage: (message, messageType) ->
    message = message?.trim()
    firebaseChat = @get 'firebaseChat'
    username = AIO.get 'currentUser.username'
    if firebaseChat && username && message && messageType
      firebaseChat.push [username, message, messageType]
      if messageType == AIO.CollabMessage.TypeChat
        this._notifyMentions message
      AIO.util.mixpanelIncrement 'ide_send_event_notification'

  _notifyMentions: (message) ->
    if mentions = this._extractMentions(message)
      activeUsers = @get 'users'
      for mention in mentions
        unless activeUsers.contains mention
          boxId = AIO.get 'router.ideController.content.id'
          AIO.Collaborator.notifyMention mention, boxId

  _extractMentions: (message) ->
    if !message || !message.match(/[@＠]/)
      return []

    mentions = []
    # regex based on twitter-text-js
    # https://github.com/twitter/twitter-text-js/blob/master/twitter-text.js
    validMentionRegex = ///
      (?:^|[^a-zA-Z0-9_!\#$%&*@＠]:?)  # Preceding character
      ([@＠])                          # At mark
      ([a-zA-Z0-9_]{1,20})             # Screen name
    ///g

    message.replace validMentionRegex, (withPreceding, atSign, mention) ->
      mentions.push mention
    mentions

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
      child.forEach (presenceObj) =>
        color = presenceObj.child('color').val()
        @get('usedUserColors')?.addObject color
        @get('users')?.addObject name: child.name(), color: color
    firebaseUsers.on 'child_removed', (child) =>
      @get('users')?.removeObject child.name()
    @set 'firebaseUsers', firebaseUsers

  _resetFirebaseUsers: ->
    @get('firebaseUsers')?.off()
    @set 'firebaseUsers', null

  _initFirebasePresenceAfterUsers: (->
    firebaseUserCount = @get 'firebaseUserCount'
    usersLoaded = @get('users').get 'length'

    if usersLoaded == firebaseUserCount
      this._setUserColor()
      this._initFirebasePresence()
  ).observes 'users', 'firebaseUserCount'

  _initFirebasePresence: ->
    boxId = AIO.get 'router.ideController.content.id'
    username = AIO.get 'currentUser.username'
    firebaseUserURL = "#{AIO.get 'firebaseHost'}/box/#{boxId}/users/#{username}"
    firebaseUser = new Firebase firebaseUserURL
    firebasePresence = firebaseUser.push()
    firebasePresence.onDisconnect().remove()
    firebasePresence.set color: @get('userColor')
    @set 'firebasePresence', firebasePresence

  _setUserColor: ->
    availableUserColors = @get 'availableUserColors'
    usedUserColors = @get('usedUserColors').toArray()
    if usedUserColors.length < availableUserColors.length
      currentlyAvailableUserColors = _.difference(availableUserColors, usedUserColors)
    else
      availableUserColorsLength = availableUserColors.length
      startingIndex = availableUserColorsLength * Math.round(usedUserColors.length / availableUserColorsLength)
      colorsUsedInCurrentIteration = usedUserColors.slice startingIndex
      currentlyAvailableUserColors = _.difference(availableUserColors, colorsUsedInCurrentIteration)
    @set 'userColor', currentlyAvailableUserColors.shift()

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
