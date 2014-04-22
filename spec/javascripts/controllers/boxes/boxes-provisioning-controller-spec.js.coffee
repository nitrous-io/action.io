describe 'App.BoxesProvisioningController', ->
  controller = null
  fakeRouter = null

  beforeEach ->
    controller = App.get('router.boxesProvisioningController')
    controller.set 'content', null

    Em.run.next = (cb) ->
      return cb()

    fakeRouter = { transitionTo: sinon.spy() }

    sinon.stub App, 'get', (param) ->
      if param == 'router.currentPath'
        return 'root.boxes.provisioning'
      else if param == "router"
        return fakeRouter

  afterEach ->
    App.get.restore()

  describe '#redirectBasedOnState', ->
    context 'when box state changes to running', ->
      box = null

      beforeEach ->
        box = Em.Object.create('state': 'running', 'id': 15)
        controller.set 'content', box

      context 'when there is a repository to clone', ->
        beforeEach ->
          controller.get('content').set('last_added_repository_id', 123)

        it 'transitions to the cloning repo screen', ->
          Em.run -> controller.redirectBasedOnState()
          expect(fakeRouter.transitionTo).to.have.been.calledWith 'box.ide', box, queryParams: { repository_id: 123 }

      context 'when there is no repository to clone', ->
        it 'transitions to the IDE', ->
          Em.run -> controller.redirectBasedOnState()
          expect(fakeRouter.transitionTo).to.have.been.calledWith 'box.ide', { id: 15 }

    it 'transition back to boxes index when box state is changed failed', ->
      controller.set 'content', Em.Object.create('state': 'failed', 'id': 15)
      Em.run -> controller.redirectBasedOnState()
      expect(fakeRouter.transitionTo).to.have.been.calledWith 'boxes.index'

    it 'displays an error dialog', ->
      controller.set 'content', Em.Object.create('state': 'failed', 'id': 15)
      Em.run -> controller.redirectBasedOnState()
      expect(App.get 'flashMessage').not.to.be.null

