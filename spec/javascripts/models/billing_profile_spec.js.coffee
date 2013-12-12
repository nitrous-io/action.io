describe "AIO.BillingProfile", ->
  billingProfile = null

  beforeEach ->
    billingProfile = AIO.BillingProfile.create()

  describe 'changeCard', ->
    cbSpy = null

    beforeEach ->
      cbSpy = sinon.spy()

    context 'when a stripe token is not provided', ->
      it 'calls the provided callback function', ->
        billingProfile.changeCard(null, cbSpy)
        expect(cbSpy).to.have.been.calledWith null

      it 'doesnt send an AJAX request to /subscription/change_card', ->
        sinon.spy(window.$, 'ajax')
        billingProfile.changeCard(null, cbSpy)
        expect(window.$.ajax).not.to.have.been.called
        window.$.ajax.restore()

    context 'when a stripe token is provided', ->
      context 'and the card is changed successfully', ->
        it 'calls the callback without an error', ->
          window.server.respondWith "PUT", "/subscription/change_card",
                                    [ 200, { "Content-Type": "application/json" }, '' ]
          billingProfile.changeCard('stripe_token', cbSpy)
          window.server.respond()
          expect(cbSpy).to.have.been.calledWith null

      context "and there's an error in changing the card", ->
        it 'calls the callback with an error', ->
          window.server.respondWith "PUT", "/subscription/change_card",
                                    [ 422, { "Content-Type": "application/json" },
                                    '{ "errors": { "base": ["Some error occurred."] } }' ]

          billingProfile.changeCard('stripe_token', cbSpy)
          window.server.respond()
          expect(cbSpy).to.have.been.calledWith 'Some error occurred.'
