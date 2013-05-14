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
      controller.reset()

    it 'hides manage collaborators dialog', ->
      expect(controller.hideManageCollaboratorsDialog).to.have.been.called

    it 'resets firebase', ->
      expect(controller._resetFirebase).to.have.been.called

    it 'sets users to be null', ->
      expect(controller.users).to.be.null

    it 'sets messages to be null', ->
      expect(controller.messages).to.be.null

  describe '#showManageCollaboratorsDialog', ->
    beforeEach ->
      controller.showManageCollaboratorsDialog()

    it 'assigns a new instance of AIO.ManageCollaboratorsDialog to manageCollaboratorsDialog attribute', ->
      expect(controller.get 'manageCollaboratorsDialog').to.be.an.instanceof AIO.ManageCollaboratorsDialog

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
      expect(controller._initFirebasePresence).to.have.been.called
      expect(controller._initFirebaseChat).to.have.been.called

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

    afterEach ->
      Firebase::on.restore()
      AIO.get.restore()

    doAction = ->
      controller._initFirebaseUsers()

    it 'initializes a new firebase instance to track online users', ->
      doAction()
      firebaseUsers = controller.get 'firebaseUsers'
      expect(firebaseUsers).to.be.an.instanceof Firebase
      expect(firebaseUsers.toString()).to.equal 'example.firebaseio.com/box/123/users'

    it 'adds a username to users array on "child_added" event', ->
      controller.set 'users', []
      Firebase::on.withArgs('child_added').callsArgWith 1, { name: -> 'foofoo' }
      doAction()
      expect(controller.get 'users').to.include 'foofoo'
      expect(controller.get 'users').to.have.length 1

    it 'removes a username from users array on "child_removed" event', ->
      controller.set 'users', ['foofoo', 'barbar']
      Firebase::on.withArgs('child_removed').callsArgWith 1, { name: -> 'foofoo' }
      doAction()
      expect(controller.get 'users').not.to.include 'foofoo'
      expect(controller.get 'users').to.include 'barbar'
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
      AIO.get.withArgs('router.applicationController.currentUser.username').returns 'foobar'
      AIO.get.withArgs('router.ideController.content.id').returns 123
      AIO.get.withArgs('firebaseHost').returns 'example.firebaseio.com'

      sinon.stub Firebase.prototype, 'push'
      firebasePresence = new Firebase('example.firebaseio.com/box/123/users/foobar/-abcde')
      Firebase::push.returns firebasePresence

      onDisconnectObject = { remove: sinon.spy() }
      sinon.stub(firebasePresence, 'onDisconnect').returns onDisconnectObject
      sinon.stub firebasePresence, 'set'

      controller._initFirebasePresence()

    afterEach ->
      Firebase::push.restore()
      AIO.get.restore()

    it 'initializes a new firebase instance for presence tracking', ->
      expect(controller.get 'firebasePresence').to.equal firebasePresence

    it 'records current session and marks it to be removed on disconnect', ->
      expect(firebasePresence.onDisconnect).to.have.been.called
      expect(onDisconnectObject.remove).to.have.been.called
      expect(firebasePresence.set).to.have.been.calledWith true

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
      AIO.get.withArgs('router.applicationController.currentUser.username').returns 'foo'
      controller.sendMessage ' hello world  ', AIO.CollabMessage.chat

    afterEach ->
      AIO.get.restore()

    it 'saves the message in firebase, removing superfluous whitespaces', ->
      expect(firebaseChat.push).to.have.been.calledWith ['foo', 'hello world', AIO.CollabMessage.chat]
