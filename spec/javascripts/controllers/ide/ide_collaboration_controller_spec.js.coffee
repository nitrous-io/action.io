describe 'AIO.IdeCollaborationController', ->
  controller = null

  beforeEach ->
    controller = AIO.IdeCollaborationController.create()

  it 'has some initial attribute values', ->
    expect(controller.get 'manageCollaboratorsDialog').to.be.null
    expect(controller.get 'firebase').to.be.null
    expect(controller.get 'firebaseAuthenticated').to.be.false

  describe '#initialize', ->
    beforeEach ->
      sinon.stub controller, '_initFirebase'
      controller.initialize()

    it 'initializes firebase', ->
      expect(controller._initFirebase).to.have.been.called

  describe '#reset', ->
    beforeEach ->
      sinon.stub controller, 'hideManageCollaboratorsDialog'
      sinon.stub controller, '_resetFirebase'
      controller.reset()

    it 'hides manage collaborators dialog', ->
      expect(controller.hideManageCollaboratorsDialog).to.have.been.called

    it 'resets firebase', ->
      expect(controller._resetFirebase).to.have.been.called

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
      server.respondWith 'GET', '/firebase/auth_token?box_id=123', [
        200
        { 'Content-Type': 'application/json; charset=utf-8' }
        JSON.stringify(auth_token: token)
      ]

    testAuthentication = ->
      expect(controller.get 'firebaseAuthenticated').to.be.false
      firebase.auth.withArgs(token).yields()
      server.respond()
      expect(controller.get 'firebaseAuthenticated').to.be.true

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
        AIO.get.withArgs('firebaseHost').returns 'https://example.firebaseio.com/'
        controller._initFirebase()

      afterEach ->
        AIO.get.restore()

      it 'initializes a new instance of firebase', ->
        firebase = controller.get 'firebase'
        expect(firebase).to.be.an.instanceof Firebase
        expect(firebase.toString()).to.equal 'https://example.firebaseio.com/'

      it 'obtains a firebase auth token from the server with current box id and authenticates with firebase', ->
        firebase = controller.get 'firebase'
        sinon.stub firebase, 'auth'
        testAuthentication()

  describe '#_resetFirebase', ->
    context 'when firebase object exists', ->
      firebase = null

      beforeEach ->
        controller.set 'firebase', new Firebase 'https://example.firebaseio.com/'
        firebase = controller.get 'firebase'
        sinon.stub firebase, 'unauth'
        controller._resetFirebase()

      it 'un-authenticates and sets firebaseAuthenticated to be false', ->
        expect(firebase.unauth).to.have.been.called
        expect(controller.get 'firebaseAuthenticated').to.be.false

      it 'preserves existing firebase object for reuse', ->
        expect(controller.get 'firebase').to.equal firebase

    context 'when firebase is not yet initialized', ->
      beforeEach ->
        controller.set 'firebase', null
        controller._resetFirebase()

      it 'sets firebaseAuthenticated to be false', ->
        expect(controller.get 'firebaseAuthenticated').to.be.false
