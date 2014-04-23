describe 'App.IdeCollaborationPaneController', ->
  box = null
  controller = null

  beforeEach ->
    controller = App.IdeCollaborationPaneController.create()
    box = App.Box.create(id: 123)
    spec.getController('boxIde').set 'content', box

  afterEach ->
    spec.getController('boxIde').set 'content', null

  it 'has some initial attribute values', ->
    expect(controller.get 'manageCollaboratorsDialog').to.be.null
    expect(controller.get 'firebase').to.be.null
    expect(controller.get 'firebaseAuthenticated').to.be.false
    expect(controller.get 'firebaseUsers').to.be.null
    expect(controller.get 'firebasePresence').to.be.null
    expect(controller.get 'firebaseChat').to.be.null
    expect(controller.get 'users').to.be.null
    expect(controller.get 'messages').to.be.null
    expect(controller.get 'userColor').to.be.null

  describe '#initialize', ->
    beforeEach ->
      sinon.stub controller, '_initFirebase'
      controller.initialize()

    it 'initializes firebase', ->
      expect(controller._initFirebase).to.have.been.called

    it 'initializes users array', ->
      expect(controller.get 'users').to.be.an.instanceof Array
      expect(controller.get 'users').to.have.length 0

    it 'initializes chat messages array', ->
      expect(controller.get 'messages').to.be.an.instanceof Array
      expect(controller.get 'messages').to.have.length 0

  describe '#reset', ->
    beforeEach ->
      sinon.stub controller, 'hideManageCollaboratorsDialog'
      sinon.stub controller, '_resetFirebase'
      controller.set 'users', ['haha']
      controller.set 'messages', [App.CollabMessage.create(username: 'foo', message: 'bar')]
      controller.set 'userColor', '#000000'
      controller.reset()

    it 'hides manage collaborators dialog', ->
      expect(controller.hideManageCollaboratorsDialog).to.have.been.called

    it 'resets firebase', ->
      expect(controller._resetFirebase).to.have.been.called

    it 'sets users to be null', ->
      expect(controller.users).to.be.null

    it 'sets messages to be null', ->
      expect(controller.messages).to.be.null

    it 'sets userColor to be null', ->
      expect(controller.userColor).to.be.null

  describe '#showManageCollaboratorsDialog', ->
    context 'when box belongs to user', ->
      beforeEach ->
        box.set 'owner_id', App.get('currentUser.id')

      it 'assigns a new instance of App.ManageCollaboratorsDialog to manageCollaboratorsDialog attribute', ->
        controller.showManageCollaboratorsDialog()
        expect(controller.get 'manageCollaboratorsDialog').to.be.an.instanceof App.ManageCollaboratorsDialog

    context 'when box does not belong to user', ->
      beforeEach ->
        box.set 'owner_id', 1337

      it 'does not assign to the manageCollaboratorsDialog attribute', ->
        expect(controller.get 'manageCollaboratorsDialog').not.to.exist

      it 'does not create a App.ManageCollaboratorsDialog', ->
        sinon.spy(App.ManageCollaboratorsDialog, 'create')
        controller.showManageCollaboratorsDialog()
        expect(App.ManageCollaboratorsDialog.create).to.not.have.been.called

  describe '#hideManageCollaboratorsDialog', ->
    beforeEach ->
      controller.set 'manageCollaboratorsDialog', sinon.spy()
      controller.hideManageCollaboratorsDialog()

    it 'nullifies manageCollaboratorsDialog', ->
      expect(controller.get 'manageCollaboratorsDialog').not.to.exist

  describe '#_initFirebase', ->
    token = 'My-Aw3s0m3-Au7h-T0k3n'
    firebase = null

    beforeEach ->
      sinon.stub controller, '_initFirebaseUsers'
      sinon.stub controller, '_setUserColor'
      sinon.stub controller, '_initFirebasePresence'
      sinon.stub controller, '_initFirebaseChat'
      server.respondWith 'GET', '/firebase/auth_token?box_id=123', [
        200
        { 'Content-Type': 'application/json; charset=utf-8' }
        JSON.stringify(auth_token: token)
      ]

    testAuthentication = ->
      expect(controller.get 'firebaseAuthenticated').to.be.false
      expect(controller._initFirebaseChat).not.to.have.been.called
      firebase.auth.withArgs(token).yields()
      server.respond()
      expect(controller.get 'firebaseAuthenticated').to.be.true
      expect(controller._initFirebaseUsers).to.have.been.called
      expect(controller._setUserColor).to.have.been.calledWith(sinon.match.func)

    context 'when firebase is already initialized', ->
      beforeEach ->
        controller.set 'firebase', new Firebase
        firebase = controller.get 'firebase'
        sinon.stub firebase, 'auth'
        controller._initFirebase()

      it 'reuses the existing instance of firebase', ->
        expect(controller.get 'firebase').to.equal firebase

      it 'obtains a firebase auth token from the server with current box id and authenticates with firebase', ->
        testAuthentication()

    context 'when firebase is not yet initialized', ->
      beforeEach ->
        controller.set 'firebase', null
        controller._initFirebase()

      it 'initializes a new instance of firebase', ->
        firebase = controller.get 'firebase'
        expect(firebase).to.be.an.instanceof Firebase
        expect(firebase.toString()).to.equal 'nitrous-firebase.example.com'

      it 'obtains a firebase auth token from the server with current box id and authenticates with firebase', ->
        firebase = controller.get 'firebase'
        sinon.stub firebase, 'auth'
        testAuthentication()

  describe '#_resetFirebase', ->
    beforeEach ->
      sinon.stub controller, '_sendLeftMessage'
      sinon.stub controller, '_resetFirebaseUsers'
      sinon.stub controller, '_resetFirebasePresence'
      sinon.stub controller, '_resetFirebaseChat'

    context 'when firebase object exists', ->
      firebase = null

      beforeEach ->
        controller.set 'firebase', new Firebase 'nitrous-firebase.example.com'
        firebase = controller.get 'firebase'
        sinon.stub firebase, 'unauth'
        controller._resetFirebase()

      it 'un-authenticates and sets firebaseAuthenticated to be false', ->
        expect(firebase.unauth).to.have.been.called
        expect(controller.get 'firebaseAuthenticated').to.be.false

      it 'preserves existing firebase object for reuse', ->
        expect(controller.get 'firebase').to.equal firebase

      it 'sends a user left message', ->
        expect(controller._sendLeftMessage).to.have.been.called

      it 'resets firebase users, presence, and chat', ->
        expect(controller._resetFirebaseUsers).to.have.been.called
        expect(controller._resetFirebasePresence).to.have.been.called
        expect(controller._resetFirebaseChat).to.have.been.called

    context 'when firebase is not yet initialized', ->
      beforeEach ->
        controller.set 'firebase', null
        controller._resetFirebase()

      it 'sets firebaseAuthenticated to be false', ->
        expect(controller.get 'firebaseAuthenticated').to.be.false

      it 'resets firebase users, presence, and chat', ->
        expect(controller._resetFirebaseUsers).to.have.been.called
        expect(controller._resetFirebasePresence).to.have.been.called
        expect(controller._resetFirebaseChat).to.have.been.called

  describe '#_initFirebaseUsers', ->
    beforeEach ->
      sinon.stub Firebase.prototype, 'on'
      sinon.stub Firebase.prototype, 'once'

    afterEach ->
      Firebase::on.restore()
      Firebase::once.restore()

    doAction = ->
      controller._initFirebaseUsers()

    it 'initializes a new firebase instance to track online users', ->
      doAction()
      firebaseUsers = controller.get 'firebaseUsers'
      expect(firebaseUsers).to.be.an.instanceof Firebase
      expect(firebaseUsers.toString()).to.equal 'nitrous-firebase.example.com/box/123/users'

    it 'adds a user object to users array and color to usedUserColors array on "child_added" event', ->
      controller.set 'users', []
      controller.set 'usedUserColors', []
      childStub = sinon.stub()
      childStub.withArgs('name').returns { val: -> 'foofoo' }
      childStub.withArgs('color').returns { val: -> '#ff0000' }
      Firebase::on.withArgs('child_added').callsArgWith 1, { child: childStub }
      doAction()

      userObj = controller.get('users').objectAt 0
      expect(controller.get 'users').to.have.length 1
      expect(userObj).to.be.an.instanceof App.CollabSessionUser
      expect(userObj.get 'name').to.equal 'foofoo'
      expect(userObj.get 'color').to.equal '#ff0000'

    it 'removes a user object from users array on "child_removed" event', ->
      user1 = App.CollabSessionUser.create name: 'foofoo', color: '#000000'
      user2 = App.CollabSessionUser.create name: 'barbar', color: '#ffffff'
      controller.set 'users', [ user1, user2 ]
      childStub = sinon.stub()
      childStub.withArgs('name').returns { val: -> 'foofoo' }
      Firebase::on.withArgs('child_removed').callsArgWith 1, { child: childStub }
      doAction()

      expect(controller.get 'users').not.to.include user1
      expect(controller.get 'users').to.include user2
      expect(controller.get 'users').to.have.length 1

  describe '#_resetFirebaseUsers', ->
    firebaseUsers = null

    beforeEach ->
      firebaseUsers = new Firebase 'nitrous-firebase.example.com/box/123/users'
      controller.set 'firebaseUsers', firebaseUsers
      sinon.stub firebaseUsers, 'off'
      controller._resetFirebaseUsers()

    it 'turns off all events and nullifies firebaseUsers', ->
      expect(firebaseUsers.off).to.have.been.called
      expect(controller.get 'firebaseUsers').not.to.exist

  describe '#_initFirebasePresence', ->
    firebasePresence = onDisconnectObject = null

    beforeEach ->
      sinon.stub Firebase.prototype, 'push'
      firebasePresence = new Firebase('nitrous-firebase.example.com/box/123/users/testuser/-abcde')
      Firebase::push.returns firebasePresence

      onDisconnectObject = { remove: sinon.spy() }
      sinon.stub(firebasePresence, 'onDisconnect').returns onDisconnectObject

      controller.set 'userColor', '#FF0000'
      controller._initFirebasePresence()

    afterEach ->
      controller.set 'userColor', null
      Firebase::push.restore()

    it 'initializes a new firebase instance for presence tracking', ->
      expect(controller.get 'firebasePresence').to.equal firebasePresence

    it 'records current session and marks it to be removed on disconnect', ->
      expect(firebasePresence.onDisconnect).to.have.been.called
      expect(onDisconnectObject.remove).to.have.been.called

  describe '#_resetFirebasePresence', ->
    firebasePresence = null

    beforeEach ->
      firebasePresence = new Firebase 'nitrous-firebase.example.com/box/123/users/testuser/-abc'
      controller.set 'firebasePresence', firebasePresence
      sinon.stub firebasePresence, 'remove'
      controller._resetFirebasePresence()

    it 'removes presence and nullifies firebasePresence', ->
      expect(firebasePresence.remove).to.have.been.called
      expect(controller.get 'firebasePresence').not.to.exist

  describe '#_setUserColor', ->
    firebasePresence = null
    callback = null

    doAction = (callback = ->)->
        controller._setUserColor callback

    beforeEach ->
      sinon.stub Firebase.prototype, 'once'
      sinon.stub Firebase.prototype, 'set'
      callback = sinon.spy()

      sinon.stub(App.UserColors, 'colors')
      App.UserColors.colors.returns ['#000', '#001', '#002', '#003']

    afterEach ->
      Firebase::once.restore()
      Firebase::set.restore()
      App.UserColors.colors.restore()

    context 'when next user color id is null', ->
      beforeEach ->
        Firebase::once.withArgs('value').callsArgWith 1, { val: -> null }
        doAction callback

      it 'sets the first color in user colors as the color for the current session', ->
        expect(controller.get 'userColor').to.equal '#000'

      it 'sets the next user color id to one', ->
        expect(Firebase::set).to.have.been.calledWith 1

      it 'calls the callback', ->
        expect(callback).to.have.been.called

    context 'next user color id is less than total user colors', ->
      beforeEach ->
        Firebase::once.withArgs('value').callsArgWith 1, { val: -> 2 }
        doAction callback

      it 'sets the next available color in user colors as the color for the current session', ->
        expect(controller.get 'userColor').to.equal '#002'

      it 'increments the next user color id by one', ->
        expect(Firebase::set).to.have.been.calledWith 3

      it 'calls the callback', ->
        expect(callback).to.have.been.called

    context 'next user color id is greater than total user colors', ->
      beforeEach ->
        Firebase::once.withArgs('value').callsArgWith 1, { val: -> 5 }
        doAction callback

      it 'sets the next color in user colors (after rotation) as the color for the current session', ->
        expect(controller.get 'userColor').to.equal '#001'

      it 'increments the next user color id by one', ->
        expect(Firebase::set).to.have.been.calledWith 6

      it 'calls the callback', ->
        expect(callback).to.have.been.called

  describe '#_initUserChatPresence', ->
    beforeEach ->
      sinon.stub controller, '_initFirebasePresence'
      sinon.stub controller, '_initFirebaseChat'
      sinon.stub controller, '_sendJoinedMessage'

    it 'sets up firebase users, presence, and sends a joined message', ->
      controller._initUserChatPresence()

      expect(controller._initFirebasePresence).to.have.been.called
      expect(controller._initFirebaseChat).to.have.been.called
      expect(controller._sendJoinedMessage).to.have.been.called

  describe '#_initFirebaseChat', ->
    beforeEach ->
      sinon.stub Firebase.prototype, 'on'

    afterEach ->
      Firebase::on.restore()

    doAction = ->
      controller._initFirebaseChat()

    it 'initializes a new Firebase instance for chat with correct URL', ->
      doAction()
      firebaseChat = controller.get 'firebaseChat'
      expect(firebaseChat).to.be.an.instanceof Firebase
      expect(firebaseChat.toString()).to.equal 'nitrous-firebase.example.com/box/123/chat'

    it 'adds a chat message to messages array on "child_added" event', ->
      controller.set 'messages', []
      Firebase::on.withArgs('child_added').callsArgWith 1, { val: -> ['pete', 'hello'] }
      doAction()
      expect(controller.get 'messages').to.have.length 1
      expect(controller.get 'messages.0.username').to.equal 'pete'
      expect(controller.get 'messages.0.message').to.equal 'hello'

    it 'calls notifyOnChatMention if chat message was added on "child_added" event', ->
      sinon.stub controller, '_notifyOnChatMention'
      Firebase::on.withArgs('child_added').callsArgWith 1, { val: -> ['pete', 'hello', App.CollabMessage.TypeChat] }
      doAction()
      expect(controller._notifyOnChatMention).to.have.been.called

  describe '#_resetFirebaseChat', ->
    firebaseChat = null

    beforeEach ->
      firebaseChat = new Firebase 'nitrous-firebase.example.com/box/123/chat'
      controller.set 'firebaseChat', firebaseChat
      sinon.stub firebaseChat, 'off'
      controller._resetFirebaseChat()

    it 'turns off all events and nullifies firebaseChat', ->
      expect(firebaseChat.off).to.have.been.called
      expect(controller.get 'firebaseChat').not.to.exist

  describe '#sendMessage', ->
    firebaseChat = null

    beforeEach ->
      controller.set 'firebaseChat', new Firebase 'nitrous-firebase.example.com/box/123/chat'
      firebaseChat = controller.get 'firebaseChat'
      sinon.stub firebaseChat, 'push'
      sinon.stub controller, '_notifyMentionsToOfflineUsers'

    afterEach ->
      controller._notifyMentionsToOfflineUsers.restore()

    context 'when a chat message', ->
      it 'saves the message in firebase, removing superfluous whitespaces', ->
        controller.sendMessage ' hello world  ', App.CollabMessage.TypeChat
        expect(firebaseChat.push).to.have.been.calledWith ['testuser', 'hello world', App.CollabMessage.TypeChat]

      it 'passes the message to mentions notifier', ->
        controller.sendMessage 'hello world', App.CollabMessage.TypeChat
        expect(controller._notifyMentionsToOfflineUsers).to.have.been.calledWith 'hello world'

    context 'when another type of a message', ->
      it 'saves the message in firebase, removing superfluous whitespaces', ->
        controller.sendMessage 'test.txt', App.CollabMessage.TypeFileOpen
        expect(firebaseChat.push).to.have.been.calledWith ['testuser', 'test.txt', App.CollabMessage.TypeFileOpen]

      it 'does not pass the message to mentions notifier', ->
        controller.sendMessage 'test.txt', App.CollabMessage.TypeFileOpen
        expect(controller._notifyMentionsToOfflineUsers).not.to.have.been.called

  describe '#_notifyMentionsToOfflineUsers', ->
    notifyMention = null

    beforeEach ->
      sinon.stub(controller, '_extractMentions').returns [ 'foo', 'bar' ]
      sinon.stub(App.Collaborator, 'notifyMention')

    afterEach ->
      controller.set 'users', Em.A()
      controller._extractMentions.restore()
      App.Collaborator.notifyMention.restore()

    context 'when mentioned user is online', ->
      beforeEach ->
        controller.set 'users', Em.A([{ name: 'foo' }, { name: 'bar' }])

      it 'does not send a notification', ->
        controller._notifyMentionsToOfflineUsers "sample message with @foo and @bar"
        expect(App.Collaborator.notifyMention).not.to.have.been.called

    context 'when mentioned user is not online', ->
      beforeEach ->
        controller.set 'users', Em.A([{ name: 'foo' }])

      it 'sends a notification', ->
        controller._notifyMentionsToOfflineUsers "sample message with @foo and @bar"
        expect(App.Collaborator.notifyMention).to.have.been.calledWith 'bar', 123

  describe '#_extractMentions', ->
    it 'extract mentions from the message', ->
      expect(controller._extractMentions('sample message mentions @foo and @bar')).to.deep.equal ['foo', 'bar']

  describe '#_sendJoinedMessage', ->
    it 'send message of type user joined', ->
      sinon.stub controller, 'sendMessage'
      controller._sendJoinedMessage()
      expect(controller.sendMessage).to.have.been.calledWith '', App.CollabMessage.TypeUserJoined

  describe '#_sendLeftMessage', ->
    it 'send message of type user left', ->
      sinon.stub controller, 'sendMessage'
      controller._sendLeftMessage()
      expect(controller.sendMessage).to.have.been.calledWith '', App.CollabMessage.TypeUserLeft

  describe '#_notifyOnChatMention', ->
    createMessage = (data) ->
      App.CollabMessage.create(username: 'pete', data: data, type: App.CollabMessage.TypeChat)

    beforeEach ->
      stubEditorSet = sinon.stub()
      sinon.stub(Audio.prototype, 'play')
      spec.getController('ideEditor').set 'chatNotification', null

    afterEach ->
      Audio::play.restore()
      spec.getController('ideEditor').set 'chatNotification', null

    context 'when message mention current user', ->
      message = createMessage('hello @testuser')

      beforeEach ->
        controller._notifyOnChatMention message

      it 'calls play on audiio object', ->
        expect(Audio::play).to.have.been.called

      it 'sets the chat notification in editor controller', ->
        spec.getController('ideEditor').get 'chatNotification', message

    context 'when message doesnt mention current user', ->
      message = createMessage('hello @bar')

      beforeEach ->
        controller._notifyOnChatMention message

      it 'does not call play on audiio object', ->
        expect(Audio::play).not.to.have.been.called

      it 'does not set the chat notification editor controller', ->
        spec.getController('ideEditor').get 'chatNotification', null
