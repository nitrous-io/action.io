describe 'AIO.Resource', ->
  resource = null

  beforeEach ->
    resource = AIO.Resource.create()

  describe '#validate', ->
    context 'when no function is present in validations object', ->
      beforeEach ->
        resource.set 'validations', {}

      it 'returns null and sets errors object to be null', ->
        expect(resource.validate()).to.be.null
        expect(resource.get('errors')).to.be.null

    context 'when no function in validations object returns error message', ->
      beforeEach ->
        resource.set 'validations',
          foo: [-> null]
          bar: -> null

      it 'returns null and sets errors object to be null', ->
        expect(resource.validate()).to.be.null
        expect(resource.get('errors')).to.be.null

    context 'when some function in validations object returns error message', ->
      beforeEach ->
        resource.set 'validations',
          foo: [(-> 'error1'), (-> 'error2'), (-> null)]
          bar: -> 'error3'
          baz: -> null

      it 'forms errors hash with the error messages returned', ->
        retVal = resource.validate()
        expect(retVal).to.deep.equal
          foo: ['error1', 'error2']
          bar: ['error3']
        expect(resource.get('errors')).to.deep.equal retVal

  describe '#firstErrors', ->
    beforeEach ->
      resource.set 'errors',
        foo: ['error1', 'error2']
        bar: ['error3']
        baz: ['error4', 'error5']

    it 'returns an object containing first error message for each key', ->
      expect(resource.get('firstErrors')).to.deep.equal
        foo: 'error1'
        bar: 'error3'
        baz: 'error4'

