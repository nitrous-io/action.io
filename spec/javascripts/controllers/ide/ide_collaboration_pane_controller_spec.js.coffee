describe 'AIO.IdeCollaborationPaneController', ->
  controller = null

  beforeEach ->
    controller = AIO.IdeCollaborationPaneController.create()

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
      controller.set 'messages', [AIO.CollabMessage.create(username: 'foo', message: 'bar')]
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
    box = null

    beforeEach ->
      box = get: ->
      sinon.stub AIO, 'get'
      AIO.get.withArgs('router.ideController.content').returns box

    afterEach ->
      AIO.get.restore()

    context 'when box belongs to user', ->
      beforeEach ->
        sinon.stub box, 'get'
        box.get.withArgs('ownBox').returns true

      it 'assigns a new instance of AIO.ManageCollaboratorsDialog to manageCollaboratorsDialog attribute', ->
        controller.showManageCollaboratorsDialog()
        expect(controller.get 'manageCollaboratorsDialog').to.be.an.instanceof AIO.ManageCollaboratorsDialog

    context 'when box does not belong to user', ->
      beforeEach ->
        sinon.stub box, 'get'
        box.get.withArgs('ownBox').returns false

      it 'does not assign to the manageCollaboratorsDialog attribute', ->
        expect(controller.get 'manageCollaboratorsDialog').not.to.exist

      it 'does not create a AIO.ManageCollaboratorsDialog', ->
        sinon.spy(AIO.ManageCollaboratorsDialog, 'create')
        controller.showManageCollaboratorsDialog()
        expect(AIO.ManageCollaboratorsDialog.create).to.not.have.been.called

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
      expect(controller._setUserColor).to.have.been.called
      # expect(controller._initFirebasePresence).to.have.been.called
      # expect(controller._initFirebaseChat).to.have.been.called

    context 'when firebase is already initialized', ->
      beforeEach ->
        controller.set 'firebase', new Firebase
        firebase = controller.get 'firebase'
        sinon.stub firebase, 'auth'
        sinon.stub(AIO, 'get').withArgs('router.ideController.content.id').returns 123
        controller._initFirebase()

      afterEach ->
        AIO.get.restore()

      it 'reuses the existing instance of firebase', ->
        expect(controller.get 'firebase').to.equal firebase

      it 'obtains a firebase auth token from the server with current box id and authenticates with firebase', ->
        testAuthentication()

    context 'when firebase is not yet initialized', ->
      beforeEach ->
        controller.set 'firebase', null
        sinon.stub(AIO, 'get')
        AIO.get.withArgs('router.ideController.content.id').returns 123
        AIO.get.withArgs('firebaseHost').returns 'example.firebaseio.com'
        controller._initFirebase()

      afterEach ->
        AIO.get.restore()

      it 'initializes a new instance of firebase', ->
        firebase = controller.get 'firebase'
        expect(firebase).to.be.an.instanceof Firebase
        expect(firebase.toString()).to.equal 'example.firebaseio.com'

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
        controller.set 'firebase', new Firebase 'example.firebaseio.com'
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
      sinon.stub AIO, 'get'
      AIO.get.withArgs('router.ideController.content.id').returns 123
      AIO.get.withArgs('firebaseHost').returns 'example.firebaseio.com'
      sinon.stub Firebase.prototype, 'on'
      sinon.stub Firebase.prototype, 'once'

    afterEach ->
      Firebase::on.restore()
      Firebase::once.restore()
      AIO.get.restore()

    doAction = ->
      controller._initFirebaseUsers()

    it 'initializes a new firebase instance to track online users', ->
      doAction()
      firebaseUsers = controller.get 'firebaseUsers'
      expect(firebaseUsers).to.be.an.instanceof Firebase
      expect(firebaseUsers.toString()).to.equal 'example.firebaseio.com/box/123/users'

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
      expect(userObj).to.be.an.instanceof AIO.CollabSessionUser
      expect(userObj.get 'name').to.equal 'foofoo'
      expect(userObj.get 'color').to.equal '#ff0000'

    it 'removes a user object from users array on "child_removed" event', ->
      user1 = AIO.CollabSessionUser.create name: 'foofoo', color: '#000000'
      user2 = AIO.CollabSessionUser.create name: 'barbar', color: '#ffffff'
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
      firebaseUsers = new Firebase 'example.firebaseio.com/box/123/users'
      controller.set 'firebaseUsers', firebaseUsers
      sinon.stub firebaseUsers, 'off'
      controller._resetFirebaseUsers()

    it 'turns off all events and nullifies firebaseUsers', ->
      expect(firebaseUsers.off).to.have.been.called
      expect(controller.get 'firebaseUsers').not.to.exist

  describe '#_initFirebasePresence', ->
    firebasePresence = onDisconnectObject = null

    beforeEach ->
      sinon.stub AIO, 'get'
      AIO.get.withArgs('currentUser.username').returns 'foobar'
      AIO.get.withArgs('router.ideController.content.id').returns 123
      AIO.get.withArgs('firebaseHost').returns 'example.firebaseio.com'

      sinon.stub Firebase.prototype, 'push'
      firebasePresence = new Firebase('example.firebaseio.com/box/123/users/foobar/-abcde')
      Firebase::push.returns firebasePresence

      onDisconnectObject = { remove: sinon.spy() }
      sinon.stub(firebasePresence, 'onDisconnect').returns onDisconnectObject

      controller.set 'userColor', '#FF0000'
      controller._initFirebasePresence()

    afterEach ->
      controller.set 'userColor', null
      Firebase::push.restore()
      AIO.get.restore()

    it 'initializes a new firebase instance for presence tracking', ->
      expect(controller.get 'firebasePresence').to.equal firebasePresence

    it 'records current session and marks it to be removed on disconnect', ->
      expect(firebasePresence.onDisconnect).to.have.been.called
      expect(onDisconnectObject.remove).to.have.been.called

  describe '#_resetFirebasePresence', ->
    firebasePresence = null

    beforeEach ->
      firebasePresence = new Firebase 'example.firebaseio.com/box/123/users/foobar/-abc'
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
      sinon.stub AIO, 'get'
      AIO.get.withArgs('firebaseHost').returns 'example.firebaseio.com'

      sinon.stub Firebase.prototype, 'once'
      sinon.stub Firebase.prototype, 'set'
      callback = sinon.spy()

    afterEach ->
      Firebase::once.restore()
      Firebase::set.restore()
      AIO.get.restore()

    context 'when next user color id is null', ->
      beforeEach ->
        Firebase::once.withArgs('value').callsArgWith 1, { val: -> null }
        doAction callback

      it 'sets the first color in user colors as the color for the current session', ->
        expect(controller.get 'userColor').to.equal AIO.UserColors[0]

      it 'sets the next user color id to one', ->
        expect(Firebase::set).to.have.been.calledWith 1

      it 'calls the callback', ->
        expect(callback).to.have.been.called

    context 'next user color id is less than total user colors', ->
      beforeEach ->
        Firebase::once.withArgs('value').callsArgWith 1, { val: -> 12 }
        doAction callback

      it 'sets the next available color in user colors as the color for the current session', ->
        expect(controller.get 'userColor').to.equal AIO.UserColors[12]

      it 'increments the next user color id by one', ->
        expect(Firebase::set).to.have.been.calledWith 13

      it 'calls the callback', ->
        expect(callback).to.have.been.called

    context 'next user color id is greater than total user colors', ->
      beforeEach ->
        Firebase::once.withArgs('value').callsArgWith 1, { val: -> 20 }
        doAction callback

      it 'sets the next color in user colors (after rotation) as the color for the current session', ->
        expect(controller.get 'userColor').to.equal AIO.UserColors[4]

      it 'increments the next user color id by one', ->
        expect(Firebase::set).to.have.been.calledWith 21

      it 'calls the callback', ->
        expect(callback).to.have.been.called

  describe '#_initFirebaseChat', ->
    beforeEach ->
      sinon.stub AIO, 'get'
      AIO.get.withArgs('router.ideController.content.id').returns 123
      AIO.get.withArgs('firebaseHost').returns 'example.firebaseio.com'
      sinon.stub Firebase.prototype, 'on'

    afterEach ->
      Firebase::on.restore()
      AIO.get.restore()

    doAction = ->
      controller._initFirebaseChat()

    it 'initializes a new Firebase instance for chat with correct URL', ->
      doAction()
      firebaseChat = controller.get 'firebaseChat'
      expect(firebaseChat).to.be.an.instanceof Firebase
      expect(firebaseChat.toString()).to.equal 'example.firebaseio.com/box/123/chat'

    it 'adds a chat message to messages array on "child_added" event', ->
      controller.set 'messages', []
      Firebase::on.withArgs('child_added').callsArgWith 1, { val: -> ['pete', 'hello'] }
      doAction()
      expect(controller.get 'messages').to.have.length 1
      expect(controller.get 'messages.0.username').to.equal 'pete'
      expect(controller.get 'messages.0.message').to.equal 'hello'

  describe '#_resetFirebaseChat', ->
    firebaseChat = null

    beforeEach ->
      firebaseChat = new Firebase 'example.firebaseio.com/box/123/chat'
      controller.set 'firebaseChat', firebaseChat
      sinon.stub firebaseChat, 'off'
      controller._resetFirebaseChat()

    it 'turns off all events and nullifies firebaseChat', ->
      expect(firebaseChat.off).to.have.been.called
      expect(controller.get 'firebaseChat').not.to.exist

  describe '#sendMessage', ->
    firebaseChat = null

    beforeEach ->
      controller.set 'firebaseChat', new Firebase 'example.firebaseio.com/box/123/chat'
      firebaseChat = controller.get 'firebaseChat'
      sinon.stub firebaseChat, 'push'
      sinon.stub AIO, 'get'
      AIO.get.withArgs('currentUser.username').returns 'foo'
      sinon.stub controller, '_notifyMentions'

    afterEach ->
      AIO.get.restore()
      controller._notifyMentions.restore()

    context 'when a chat message', ->
      it 'saves the message in firebase, removing superfluous whitespaces', ->
        controller.sendMessage ' hello world  ', AIO.CollabMessage.TypeChat
        expect(firebaseChat.push).to.have.been.calledWith ['foo', 'hello world', AIO.CollabMessage.TypeChat]

      it 'passes the message to mentions notifier', ->
        controller.sendMessage 'hello world', AIO.CollabMessage.TypeChat
        expect(controller._notifyMentions).to.have.been.calledWith 'hello world'

    context 'when another type of a message', ->
      it 'saves the message in firebase, removing superfluous whitespaces', ->
        controller.sendMessage 'test.txt', AIO.CollabMessage.TypeFileOpen
        expect(firebaseChat.push).to.have.been.calledWith ['foo', 'test.txt', AIO.CollabMessage.TypeFileOpen]

      it 'does not pass the message to mentions notifier', ->
        controller.sendMessage 'test.txt', AIO.CollabMessage.TypeFileOpen
        expect(controller._notifyMentions).not.to.have.been.called

  describe '#_notifyMentions', ->
    notifyMention = null

    beforeEach ->
      sinon.stub(controller, '_extractMentions').returns [ 'foo', 'bar' ]
      sinon.stub controller, 'get'
      sinon.stub AIO, 'get'
      sinon.stub(AIO.Collaborator, 'notifyMention')

    afterEach ->
      controller._extractMentions.restore()
      controller.get.restore()
      AIO.get.restore()
      AIO.Collaborator.notifyMention.restore()

    context 'when mentioned user is online', ->
      beforeEach ->
        controller.get.withArgs('users').returns [ { name: 'foo' }, { name: 'bar' } ]

      it 'does not send a notification', ->
        controller._notifyMentions "sample message with @foo and @bar"
        expect(AIO.Collaborator.notifyMention).not.to.have.been.called

    context 'when mentioned user is not online', ->
      beforeEach ->
        controller.get.withArgs('users').returns [ 'foo' ]
        AIO.get.withArgs('router.ideController.content.id').returns 5

      it 'sends a notification', ->
        controller._notifyMentions "sample message with @foo and @bar"
        expect(AIO.Collaborator.notifyMention).to.have.been.calledWith 'bar', 5

  describe '#_extractMentions', ->
    it 'extract mentions from the message', ->
      expect(controller._extractMentions('sample message mentions @foo and @bar')).to.deep.equal ['foo', 'bar']

  describe '#_sendJoinedMessage', ->
    it 'send message of type user joined', ->
      sinon.stub controller, 'sendMessage'
      controller._sendJoinedMessage()
      expect(controller.sendMessage).to.have.been.calledWith '', AIO.CollabMessage.TypeUserJoined

  describe '#_sendLeftMessage', ->
    it 'send message of type user left', ->
      sinon.stub controller, 'sendMessage'
      controller._sendLeftMessage()
      expect(controller.sendMessage).to.have.been.calledWith '', AIO.CollabMessage.TypeUserLeft

