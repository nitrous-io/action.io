describe "AIO.Subscription", ->
  subscription = null

  beforeEach ->
    subscription = AIO.Subscription.create()

  describe 'active', ->
    it 'should return true when the state is active', ->
      subscription.set 'state', 'active'
      expect(subscription.get 'active').to.be.true

    it 'should return false when the state is pending', ->
      subscription.set 'state', 'pending'
      expect(subscription.get 'active').to.be.false

    it 'should return false when the state is canceled', ->
      subscription.set 'state', 'canceled'
      expect(subscription.get 'active').to.be.false

  describe 'changePlan', ->
    cbSpy = null

    beforeEach ->
      cbSpy = sinon.spy()

    context 'when the plan is changed successfully', ->
      it 'calls the callback without an error', ->
        window.server.respondWith "PUT", "/subscription",
                                  [ 200, { "Content-Type": "application/json" }, '' ]
        subscription.changePlan(1, cbSpy)
        window.server.respond()
        expect(cbSpy).to.have.been.calledWith null

    context "when there's an error in changing the plan", ->
      it 'calls the callback with an error', ->
        window.server.respondWith "PUT", "/subscription",
                                  [ 422, { "Content-Type": "application/json" },
                                  '{ "errors": { "base": ["Some error occurred."] } }' ]

        subscription.changePlan(1, cbSpy)
        window.server.respond()
        expect(cbSpy).to.have.been.calledWith 'Some error occurred.'

  describe 'cancel', ->
    cbSpy = null

    beforeEach ->
      cbSpy = sinon.spy()

    context 'when the subscription is canceled successfully', ->
      it 'calls the callback without an error', ->
        window.server.respondWith "DELETE", "/subscription",
                                  [ 200, { "Content-Type": "application/json" }, '' ]
        subscription.cancel(cbSpy)
        window.server.respond()
        expect(cbSpy).to.have.been.calledWith null

    context "when there's an error in canceling a subscription", ->
      it 'calls the callback with an error', ->
        window.server.respondWith "DELETE", "/subscription",
                                  [ 422, { "Content-Type": "application/json" },
                                  '{ "errors": { "base": ["Some error occurred."] } }' ]

        subscription.cancel(cbSpy)
        window.server.respond()
        expect(cbSpy).to.have.been.calledWith 'Some error occurred.'

  describe '.subscribe', ->
    cbSpy = null

    beforeEach ->
      cbSpy = sinon.spy()

    context 'when the subscription is created successfully', ->
      it 'calls the callback without an error', ->
        window.server.respondWith "POST", "/subscription",
                                  [ 200, { "Content-Type": "application/json" }, '' ]
        AIO.Subscription.subscribe(1, 'stripe_token', cbSpy)
        window.server.respond()
        expect(cbSpy).to.have.been.calledWith null

    context "when there's an error in creating a subscription", ->
      it 'calls the callback with an error', ->
        window.server.respondWith "POST", "/subscription",
                                  [ 422, { "Content-Type": "application/json" },
                                  '{ "errors": { "base": ["Some error occurred."] } }' ]

        AIO.Subscription.subscribe(1, 'stripe_token', cbSpy)
        window.server.respond()
        expect(cbSpy).to.have.been.calledWith 'Some error occurred.'
