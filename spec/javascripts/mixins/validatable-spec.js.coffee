ValidatableObject = Em.Object.extend App.Validatable

describe 'App.Validatable', ->
  object = null

  beforeEach ->
    object = ValidatableObject.create()

  describe '#validate', ->
    context 'when no function is present in validations object', ->
      beforeEach ->
        object.set 'validations', {}

      it 'returns null and sets errors object to be null', ->
        expect(object.validate()).to.be.null
        expect(object.get 'errors').to.be.null

    context 'when no function in validations object returns error message', ->
      beforeEach ->
        object.set 'validations',
          foo: [-> null]
          bar: -> null

      it 'returns null and sets errors object to be null', ->
        expect(object.validate()).to.be.null
        expect(object.get 'errors').to.be.null

    context 'when some function in validations object returns error message', ->
      beforeEach ->
        object.set 'validations',
          foo: [(-> 'error1'), (-> 'error2'), (-> null)]
          bar: -> 'error3'
          baz: -> null

      it 'forms errors hash with the error messages returned', ->
        retVal = object.validate()
        expect(retVal).to.deep.equal
          foo: ['error1', 'error2']
          bar: ['error3']
        expect(object.get 'errors').to.deep.equal retVal

  describe '#firstErrors', ->
    beforeEach ->
      object.set 'errors',
        foo: ['error1', 'error2']
        bar: ['error3']
        baz: ['error4', 'error5']

    it 'returns an object containing first error message for each key', ->
      expect(object.get 'firstErrors').to.deep.equal
        foo: 'error1'
        bar: 'error3'
        baz: 'error4'

