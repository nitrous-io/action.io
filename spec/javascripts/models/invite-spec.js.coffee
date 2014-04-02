describe 'App.Invite', ->
  model = null

  beforeEach ->
    model = App.Invite.create()

  describe 'validations', ->
    context 'email', ->
      it 'validates email to not exist', ->
        model.set 'email', null
        model.validate()
        expect(model.get 'errors.email').to.exist

  describe 'humanizedState', ->
    it 'should return a humanized version of the state', ->
      model.set 'state', 'accepted'
      expect(model.get 'humanizedState').to.eql 'accepted'

      model.set 'state', 'activated'
      expect(model.get 'humanizedState').to.eql 'sent'

  describe 'humanizedN2OEarned', ->
    it 'should return a humanized N2O', ->
      model.set 'n2o_earned', 20
      expect(model.get 'humanizedN2OEarned').to.eql '+20'

      model.set 'n2o_earned', null
      expect(model.get 'humanizedN2OEarned').to.eql ''

