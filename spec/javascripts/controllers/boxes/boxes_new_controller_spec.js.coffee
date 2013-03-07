describe 'AIO.BoxesNewController', ->
  controller = router = null

  beforeEach ->
    router = AIO.lookup('router:main')
    Em.run ->
      router.transitionTo 'boxes.new'
      controller = AIO.lookup("controller:boxesNew")

  describe '#cancel', ->
    it 'cancels the creation and navigates back to index', ->
      expect(router.get('url')).to.equal '/boxes/new'
      Em.run -> controller.cancel()
      expect(router.get('url')).to.equal '/boxes'
