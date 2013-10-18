describe "AIO.BillingProfile", ->
  billingProfile = null

  beforeEach ->
    billingProfile = AIO.BillingProfile.create()

  describe 'upgrade', ->
    cbSpy = null

    beforeEach ->
      cbSpy = sinon.spy()

    context 'neither plan nor card details were changed', ->
      beforeEach ->
        sinon.stub(billingProfile, 'get').withArgs('activeSubscriptionPlan').returns AIO.SubscriptionPlan.create({ id: 1 })

      it 'calls the callback without any error', ->
        billingProfile.upgrade 1, null, null, cbSpy
        expect(cbSpy).to.have.been.calledWith null

    context 'on a new billing profile', ->
      beforeEach ->
        billingProfile.set 'id', null

      context 'subscription is created successfully', ->
        beforeEach ->
          window.server.respondWith "POST", "/subscription",
                                  [ 200, { "Content-Type": "application/json" }, '' ]

        it 'calls the callback without any errors', ->
          billingProfile.upgrade 2, 'stripe_token', 'coupon_code', cbSpy
          window.server.respond()
          expect(cbSpy).to.have.been.calledWith null

      context 'when there are errors in creating the subscription', ->
        beforeEach ->
          window.server.respondWith "POST", "/subscription",
                                  [ 422, { "Content-Type": "application/json" },
                                  '{ "errors": { "base": ["Some error occurred."] } }' ]

        it 'calls the callback with the error message returned from the server', ->
          billingProfile.upgrade 2, 'stripe_token', 'coupon_code', cbSpy
          window.server.respond()
          expect(cbSpy).to.have.been.calledWith 'Some error occurred.'

    context 'on an exisiting billing profile', ->
      beforeEach ->
        sinon.stub(billingProfile, 'get')
        billingProfile.get.withArgs('activeSubscriptionPlan').returns AIO.SubscriptionPlan.create({ id: 1 })
        billingProfile.get.withArgs('id').returns 1

      context 'subscription is created successfully', ->
        beforeEach ->
          window.server.respondWith "PUT", "/subscription",
                                  [ 200, { "Content-Type": "application/json" },
                                  '' ]

        it 'calls the callback without any errors', ->
          billingProfile.upgrade 2, 'stripe_token', 'coupon_code', cbSpy
          window.server.respond()
          expect(cbSpy).to.have.been.calledWith null

      context 'when there are errors in creating the subscription', ->
        beforeEach ->
          window.server.respondWith "PUT", "/subscription",
                                  [ 422, { "Content-Type": "application/json" },
                                  '{ "errors": { "base": ["Some error occurred."] } }' ]

        it 'calls the callback with the error message returend from the server', ->
          billingProfile.upgrade 2, 'stripe_token', 'coupon_code', cbSpy
          window.server.respond()
          expect(cbSpy).to.have.been.calledWith 'Some error occurred.'
