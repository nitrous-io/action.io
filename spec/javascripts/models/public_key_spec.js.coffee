#= require spec_helper

describe 'AIO.PublicKey', ->
  model = null

  beforeEach ->
    model = AIO.PublicKey.create()

  describe 'validations', ->

    context 'key', ->

      it 'validates key not to exist', ->
        model.validate()
        expect(model.get 'errors.key').to.exist

      it 'validates key to exist', ->
        model.set 'key', 'foo'
        expect(model.get 'errors.key').not.to.exist
