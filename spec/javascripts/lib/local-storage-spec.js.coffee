describe 'App.localStorage', ->
  beforeEach -> window.localStorage.clear()
  afterEach  -> window.localStorage.clear()

  describe '.set', ->
    context 'when the given value is not null', ->
      it 'stores a json representation of a given object in local storage, with namespaced key', ->
        obj = { foo: "bar" }
        App.localStorage.set 'localStorageTest', obj
        expect(window.localStorage.getItem 'aio:localStorageTest').to.equal JSON.stringify(obj)

    context 'when the given value is null', ->
      it 'removes the object from local storage', ->
        App.localStorage.set 'localStorageTest', { foo: "bar" }
        expect(window.localStorage.length).to.equal 1
        App.localStorage.set 'localStorageTest', null
        expect(window.localStorage.length).to.equal 0

    context 'when the given value is undefined', ->
      it 'removes the object from local storage', ->
        App.localStorage.set 'localStorageTest', { foo: "bar" }
        expect(window.localStorage.length).to.equal 1
        App.localStorage.set 'localStorageTest', undefined
        expect(window.localStorage.length).to.equal 0

  describe '.get', ->
    it 'fetches an item previously stored with ".set"', ->
      App.localStorage.set 'foo', ['foo', 'bar']
      App.localStorage.set 'bar', 123
      App.localStorage.set 'baz', true

      expect(App.localStorage.get 'foo').to.deep.equal ['foo', 'bar']
      expect(App.localStorage.get 'bar').to.equal 123
      expect(App.localStorage.get 'baz').to.be.true
