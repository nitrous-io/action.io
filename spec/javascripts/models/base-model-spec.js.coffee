describedClass = TestBaseModel = AIO.BaseModel.extend
  name: Em.attr()
  age: Em.attr(Number)

describe 'AIO.BaseModel', ->
  it 'camelizes keys', ->
    expect(describedClass.camelizeKeys).to.be.false

  it 'uses AIO.RESTAdapter', ->
    expect(describedClass.adapter).to.be.an.instanceOf AIO.RESTAdapter

  describe '#makeRequest', ->
    adapter = describedClass.adapter
    record = null

    beforeEach ->
      record = TestBaseModel.create()
      sinon.stub adapter, 'makeRequest'

    afterEach ->
      adapter.makeRequest.restore()

    it "delegates to the adapter's makeRequest method", ->
      record.makeRequest 'foo'
      expect(adapter.makeRequest).to.have.been.calledWith record, 'foo', 'GET', undefined
      adapter.makeRequest.reset()

      record.makeRequest 'bar', 'PUT'
      expect(adapter.makeRequest).to.have.been.calledWith record, 'bar', 'PUT', undefined
      adapter.makeRequest.reset()

      record.makeRequest 'baz', 'DELETE', qux: '123'
      expect(adapter.makeRequest).to.have.been.calledWith record, 'baz', 'DELETE', { qux: '123' }


  describe '#loadHash', ->
    it 'is a shortcut for #load(id, hash)', ->
      record = TestBaseModel.create()
      sinon.stub record, 'load'
      hash = { id: 123, name: 'Foo', age: 18 }
      record.loadHash(hash)
      expect(record.load).to.have.been.calledWith 123, hash

    it 'also works if custom field is used for primary key', ->
      testModel = TestBaseModel.extend
        the_id: Em.attr()
      testModel.reopenClass
        primaryKey: 'the_id'

      record = testModel.create()
      sinon.stub record, 'load'
      hash = { the_id: 747, name: 'Bar', age: 20 }
      record.loadHash(hash)
      expect(record.load).to.have.been.calledWith 747, hash

  describe '.all', ->
    context 'when @_findAllRecordArray already exists', ->
      existingArray = sinon.spy()

      beforeEach ->
        TestBaseModel._findAllRecordArray = existingArray

      afterEach ->
        delete TestBaseModel._findAllRecordArray

      it 'returns existing @_findAllRecordArray', ->
        expect(TestBaseModel.all()).to.equal existingArray

    context 'when @_findAllRecordArray does not exist yet', ->
      it 'creates and returns an empty record array', ->
        recordArray = TestBaseModel.all()
        expect(recordArray).to.be.instanceOf(Em.RecordArray)
        expect(recordArray.get 'modelClass').to.equal TestBaseModel

  describe '.preload', ->
    recordArray = null

    beforeEach ->
      recordArray = TestBaseModel.preload [
        { id: 1, name: 'Foo', age: 20 }
        { id: 2, name: 'Bar', age: 30 }
        { id: 3, name: 'Baz', age: 18 }
      ]

    it 'returns a record array', ->
      expect(recordArray).to.be.instanceOf(Em.RecordArray)
      expect(recordArray.get 'modelClass').to.equal TestBaseModel

    it 'contains records', ->
      records = recordArray.get 'content'
      expect(records).to.have.lengthOf 3
      expect(records[0]).to.be.instanceOf TestBaseModel
      expect(records[1]).to.be.instanceOf TestBaseModel
      expect(records[2]).to.be.instanceOf TestBaseModel
      expect(records[0].get 'id').to.equal 1
      expect(records[1].get 'id').to.equal 2
      expect(records[2].get 'id').to.equal 3
      expect(records[0].get 'name').to.equal 'Foo'
      expect(records[1].get 'name').to.equal 'Bar'
      expect(records[2].get 'name').to.equal 'Baz'
      expect(records[0].get 'age').to.equal 20
      expect(records[1].get 'age').to.equal 30
      expect(records[2].get 'age').to.equal 18
      expect(records[0]).to.equal TestBaseModel.findById(1)
      expect(records[1]).to.equal TestBaseModel.findById(2)
      expect(records[2]).to.equal TestBaseModel.findById(3)
