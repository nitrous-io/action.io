describe 'AIO.BoxesProvisioningController', ->
  controller = null
  fakeRouter = null

  beforeEach ->
    controller = AIO.get('router.boxesProvisioningController')
    controller.set 'content', null

    Em.run.next = (cb) ->
      return cb()

    fakeRouter = { transitionTo: sinon.spy() }

    sinon.stub AIO, 'get', (param) ->
      if param == 'router.currentPath'
        return 'root.boxes.provisioning'
      else if param == "router"
        return fakeRouter

  afterEach ->
    AIO.get.restore()

  describe '#redirectBasedOnState', ->
    context 'when box state changes to running', ->
      beforeEach ->
        controller.set 'content', Em.Object.create('state': 'running', 'id': 15)

      context 'when there is a repository to clone', ->
        beforeEach ->
          controller.get('content').set('repository_to_clone', Em.Object.create())

        it 'transitions to the cloning repo screen', ->
          Em.run -> controller.redirectBasedOnState()
          expect(fakeRouter.transitionTo).to.have.been.calledWith 'boxes.cloning_repo', { id: 15 }

      context 'when there is no repository to clone', ->
        it 'transitions to the IDE', ->
          Em.run -> controller.redirectBasedOnState()
          expect(fakeRouter.transitionTo).to.have.been.calledWith 'boxes.ide', { id: 15 }

    it 'transition back to boxes index when box state is changed failed', ->
      controller.set 'content', Em.Object.create('state': 'failed', 'id': 15)
      Em.run -> controller.redirectBasedOnState()
      expect(fakeRouter.transitionTo).to.have.been.calledWith 'boxes.index'

    it 'displays an error dialog', ->
      controller.set 'content', Em.Object.create('state': 'failed', 'id': 15)
      Em.run -> controller.redirectBasedOnState()
      expect(AIO.get 'flashMessage').not.to.be.null

