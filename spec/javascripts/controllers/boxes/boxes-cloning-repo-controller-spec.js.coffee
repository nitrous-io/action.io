describe 'App.BoxesCloningRepoController', ->
  controller = null
  fakeRouter = null
  box = null
  repository = null

  beforeEach ->
    controller = App.get('router.boxesCloningRepoController')
    controller.set 'content', null

    Em.run.next = (cb) ->
      return cb()

    fakeRouter = { transitionTo: sinon.spy() }

    sinon.stub App, 'get', (param) ->
      if param == 'router.currentPath'
        return 'root.boxes.cloning_repo'
      else if param == "router"
        return fakeRouter

  afterEach ->
    App.get.restore()

  describe '#redirectBasedOnState', ->
    context 'when box state changes to running', ->
      beforeEach ->
        controller.set 'content', Em.Object.create(id: 123, state: 'running', repository_id_to_clone: 456)

      it 'transitions to ide with repo', ->
        Em.run -> controller.redirectBasedOnState()
        expect(fakeRouter.transitionTo).to.have.been.calledWith 'boxes.ide_with_repo', id: 123, repo_id: 456
