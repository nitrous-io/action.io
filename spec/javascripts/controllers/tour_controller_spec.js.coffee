describe 'AIO.TourController', ->
  controller = null
  user = AIO.User.create()

  beforeEach ->
    controller = AIO.TourController.create()
    sinon.stub(AIO, 'get').withArgs('router.applicationController.currentUser').returns user

  afterEach ->
    AIO.get.restore()

  it 'sets initial attributes', ->
    expect(controller.get 'tour').to.be.null
    expect(controller.get 'step').to.be.null
    expect(controller.get 'sign_in_limit').to.equal 5

  describe '#initialize', ->
    it 'starts the tour and sets the tour attribute', ->
      controller.initialize 'some_tour'
      expect(controller.tour).to.be.equal 'some_tour'

  describe '#reset', ->
    beforeEach ->
      controller.set 'step', 5
      controller.set 'tour', 'some_tour'
      controller.reset()

    it 'resets step', ->
      expect(controller.step).to.be.null

    it 'resets tour', ->
      expect(controller.tour).to.be.null

  describe '#start', ->
    beforeEach ->
      controller.set 'step', null
      controller.start()

    it 'sets step to 0', ->
      expect(controller.step).to.equal 0

  describe '#nextStep', ->
    doAction = ->
      Em.run ->
        controller.nextStep()

    context 'when step is not null', ->
      beforeEach ->
        controller.set 'step', 1
        doAction()

      it 'increments step by 1', ->
        expect(controller.step).to.equal 2

    context 'when step is null', ->
      beforeEach ->
        controller.set 'step', null
        doAction()

      it 'does not increment step', ->
        expect(controller.step).to.equal null

  describe '#close', ->
    beforeEach ->
      controller.set 'step', 3
      controller.set 'tour','my_tour'
      sinon.spy user, 'hideTour'
      controller.close()

    afterEach ->
      user.hideTour.restore()

    it 'sets step to null', ->
      expect(controller.step).to.equal null

    it 'calles hideTour on user with my_tour', ->
      expect(user.hideTour).to.have.been.calledWith 'my_tour'
