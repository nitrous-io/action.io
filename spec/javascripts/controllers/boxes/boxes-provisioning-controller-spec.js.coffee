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
    it 'transition to IDE when box state is changed running', ->
      controller.set 'content', Em.Object.create('state': 'running', 'id': 15)
      Em.run -> controller.redirectBasedOnState()
      expect(fakeRouter.transitionTo).to.have.been.calledWith 'boxes.ide', { id: 15 }

    it 'transition back to boxes index when box state is changed failed', ->
      controller.set 'content', Em.Object.create('state': 'failed', 'id': 15)
      Em.run -> controller.redirectBasedOnState()
      expect(fakeRouter.transitionTo).to.have.been.calledWith 'boxes.index'

    it 'displays an error dialog', ->
      controller.set 'content', Em.Object.create('state': 'failed', 'id': 15)
      Em.run -> controller.redirectBasedOnState()
      expect(App.get 'flashMessage').not.to.be.null

