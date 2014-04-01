describe 'AIO.BoxesCloningRepoController', ->
  controller = null
  fakeRouter = null
  box = null
  repository = null

  beforeEach ->
    controller = AIO.get('router.boxesCloningRepoController')
    controller.set 'content', null

    Em.run.next = (cb) ->
      return cb()

    fakeRouter = { transitionTo: sinon.spy() }

    sinon.stub AIO, 'get', (param) ->
      if param == 'router.currentPath'
        return 'root.boxes.cloning_repo'
      else if param == "router"
        return fakeRouter

  afterEach ->
    AIO.get.restore()

  describe '#redirectBasedOnRepoState', ->
    context 'when repo state changes to cloned', ->
      beforeEach ->
        controller.set 'repository', Em.Object.create(state: 'cloned', id: 456)
        controller.set 'content', Em.Object.create(id: 123)

      it 'transitions to ide with repo', ->
        Em.run -> controller.redirectBasedOnRepoState()
        expect(fakeRouter.transitionTo).to.have.been.calledWith 'boxes.ide_with_repo', id: 123, repo_id: 456

    context 'when repo state changes to identified', ->
      beforeEach ->
        controller.set 'repository', Em.Object.create(state: 'identified')
        box = { cloneRepo: sinon.spy() }
        controller.set 'content', box

      afterEach ->

      context 'when the repository scm is supported', ->
        beforeEach ->
          repository = Em.Object.create
            state: 'identified'
            supported: ->
              true
          controller.set 'repository', repository

        it 'starts cloning', ->
          Em.run -> controller.redirectBasedOnRepoState()
          expect(box.cloneRepo).to.have.been.calledWith repository

      context 'when repository scm is not supported', ->
        beforeEach ->
          repository = Em.Object.create
            state: 'identified'
            supported: ->
              false
          controller.set 'repository', repository
          controller.set 'content', box
          sinon.spy controller, 'returnToPicker'

        afterEach ->
          controller.returnToPicker.restore()

        it 'returns to clone repo picker', ->
          Em.run -> controller.redirectBasedOnRepoState()
          expect(controller.returnToPicker).to.have.been.calledWith "This does not look like a Git or Mercurial repository."

  describe '#returnToPicker', ->
    beforeEach ->
      sinon.spy AIO, 'set'

    afterEach ->
      AIO.set.restore()

    it 'sets errors on CloneRepoPicker', ->
      Em.run -> controller.returnToPicker('bad repo')
      expect(AIO.set).to.have.been.calledWith 'router.boxesCloneRepoPickerController.errors', 'bad repo'

    it 'transitions to CloneRepoPicker', ->
      Em.run -> controller.returnToPicker('bad repo')
      expect(fakeRouter.transitionTo).to.have.been.calledWith 'boxes.clone_repo_picker'
