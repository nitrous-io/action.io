describe 'App.RESTAdapter', ->
  describedClass = App.RESTAdapter
  adapter = null

  beforeEach ->
    adapter = describedClass.create()

  it 'is a subclass of Ember.RESTAdapter', ->
    expect(adapter).to.be.an.instanceOf Ember.RESTAdapter

  describe '#makeRequest', ->
    FakeModel = Em.Model.extend
      _id: Em.attr()

    FakeModel.reopenClass
      primaryKey: '_id'
      url: 'https://www.example.com/boxes'

    beforeEach ->
      sinon.stub adapter, 'ajax'

    context 'when primary key attribute exists', ->
      it 'calls ajax with properly constructed url including the id and action name', ->
        record = FakeModel.create _id: 1337, id: 123
        adapter.makeRequest record, 'update_something', 'PUT', foo: 'bar'
        expect(adapter.ajax).to.have.been.calledWith 'https://www.example.com/boxes/1337/update_something.json', { foo: 'bar' }, 'PUT'
        adapter.ajax.reset()

      context 'when action is not given', ->
        it 'calls ajax with properly constructed url including the id', ->
          record = FakeModel.create _id: 1337, id: 123
          adapter.makeRequest record, null, 'DELETE', foo: 'bar'
          expect(adapter.ajax).to.have.been.calledWith 'https://www.example.com/boxes/1337.json', { foo: 'bar' }, 'DELETE'
          adapter.ajax.reset()

    context 'when primary key attribute does not exist', ->
      it 'calls ajax with url that does not include the id', ->
        record = FakeModel.create()
        adapter.makeRequest record, 'update_something', 'PUT', foo: 'bar'
        expect(adapter.ajax).to.have.been.calledWith 'https://www.example.com/boxes/update_something.json', { foo: 'bar' }, 'PUT'

      context 'when action is not given', ->
        it 'calls ajax with url that does not include the id', ->
          record = FakeModel.create()
          adapter.makeRequest record, null, 'DELETE', foo: 'bar'
          expect(adapter.ajax).to.have.been.calledWith 'https://www.example.com/boxes.json', { foo: 'bar' }, 'DELETE'
