describe 'App.N2oUpgradeController', ->
  controller = null

  beforeEach ->
    controller = App.N2oUpgradeController.create()
    App.set 'currentUser', App.CurrentUser.create()

    selectedPlan = App.Plan.create()
    sinon.stub(selectedPlan, 'get').withArgs('price').returns 19.99
    controller.set 'selectedPlan', selectedPlan

  describe '#discount', ->
    context 'when the current user has a coupon', ->
      beforeEach ->
        sinon.stub(App.currentUser, 'get').withArgs('coupon').returns { percent_off: 50 }

      it 'returns the discount calculated for the selected plan', ->
        expect(controller.get('discount')).to.equal 9.995

    context 'when the current user doesnt have a coupon', ->
      beforeEach ->
        sinon.stub(App.currentUser, 'get').withArgs('coupon').returns null

      it 'returns 0', ->
        expect(controller.get('discount')).to.equal 0

  describe '#total', ->
    context 'when the current user has a coupon', ->
      beforeEach ->
        sinon.stub(App.currentUser, 'get').withArgs('coupon').returns { percent_off: 50 }

      it 'returns the total reducing the coupon discount from the selected plan price', ->
        expect(controller.get('total')).to.equal 9.995

    context 'when the current user doesnt have a coupon', ->
      beforeEach ->
        sinon.stub(App.currentUser, 'get').withArgs('coupon').returns null

      it 'returns the price of the selected plan as the total', ->
        expect(controller.get('total')).to.equal 19.99
