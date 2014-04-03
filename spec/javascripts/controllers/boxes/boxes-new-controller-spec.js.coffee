describe 'App.BoxesNewController', ->
  controller = null

  beforeEach ->
    controller = App.BoxesNewController.create()

  describe '#newRecord', ->
    beforeEach ->
      sinon.stub controller, 'handleIntent'
      controller.newRecord()

    afterEach ->
      controller.handleIntent.restore()

    it 'creates a new clean box with template id', ->
      box = controller.get('content')
      expect(box.get 'isNew').to.be.true

    it 'calls handleIntent', ->
      expect(controller.handleIntent).to.have.been.called

  describe '#handleIntent', ->
    box = user = null

    beforeEach ->
      user = App.get('currentUser')
      box = App.Box.create()
      controller.set 'content', box

    afterEach ->
      user.set 'intent', null

    context 'when the current user has an intended clone repo URL', ->
      beforeEach ->
        user.set 'intent', { kind: 'clone_repo', data: { url: 'https://github.com/rails/rails.git' } }

      it 'sets the repository_clone_url to the intended clone repo URL', ->
        controller.handleIntent()
        expect(box.get 'repository_clone_url').to.equal('https://github.com/rails/rails.git')

    context 'when the current user does not have an intended clone repo URL', ->
      beforeEach ->
        user.set 'intent', { kind: 'clone_repo', data: {} }

      it 'does not set the repository_clone_url', ->
        controller.handleIntent()
        expect(box.get 'repository_clone_url').not.to.exist
