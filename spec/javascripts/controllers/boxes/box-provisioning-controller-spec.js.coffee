describe 'App.BoxProvisioningController', ->
  controller = null
  fakeRouter = null

  beforeEach ->
    controller = spec.getController 'boxProvisioning'
    controller.set 'content', null

    #fakeRouter = { transitionTo: sinon.spy() }

    #sinon.stub App, 'get', (param) ->
      #if param == 'router.currentPath'
        #return 'root.boxes.provisioning'
      #else if param == "router"
        #return fakeRouter

  describe '#redirectBasedOnState', ->
    context 'when box state changes to running', ->
      box = null

      beforeEach ->
        box = Em.Object.create(state: 'running', id: 15)
        controller.set 'content', box

      context 'when there is a repository to clone', ->
        repo = null

        beforeEach ->
          box.set('last_added_repository_id', 123)
          repo = App.Repository.create(id: 123)
          App.Repository.all().set 'content', Em.A([repo])

        afterEach ->
          App.Repository.all().set 'content', Em.A()

        it 'transitions to the cloning repo screen', (done) ->
          controller.redirectBasedOnState()
          Em.run.scheduleOnce 'afterRender', this, ->
            route = spec.getCurrentRoute()
            expect(route.routeName).to.equal 'box.ide'
            expect(route.currentModel).to.equal box
            expect(route.controller.get 'repository').to.equal repo
            done()

      context 'when there is no repository to clone', ->
        it 'transitions to the IDE', (done) ->
          controller.redirectBasedOnState()
          Em.run.scheduleOnce 'afterRender', this, ->
            route = spec.getCurrentRoute()
            expect(route.routeName).to.equal 'box.ide'
            expect(route.currentModel).to.equal box
            done()

    context 'when box state is failed', ->
      beforeEach ->
        App.set 'flashMessage', null
        controller.set 'content', Em.Object.create(state: 'failed', id: 15)
        controller.redirectBasedOnState()

      it 'transition back to boxes with a flash message', (done) ->
        Em.run.scheduleOnce 'afterRender', this, ->
          expect(spec.getCurrentRouteName()).to.equal 'boxes.index'
          expect(App.get 'flashMessage').not.to.be.null
          done()
