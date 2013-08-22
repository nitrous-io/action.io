# server is the glocal sinon mock server that we instantiate in spec_helper
describe "AIO.Model", ->
  klass = null
  beforeEach ->
    klass = AIO.Model.extend({})
    klass.reopenClass
      resourceName: 'klass'
      resourceUrl: '/klasses'
      jsonRoot: 'klasses'

  describe ".loadAll", ->
    it 'loads arrays of data as model record', ->
      Em.run -> klass.loadAll [{id: 1}, {id: 2}]
      # _data is where we cached the records internally
      records = klass._data
      expect(records.mapProperty("id")).to.have.members [1, 2]
      expect(records.get("firstObject.id")).to.eql 1
      expect(records.get("lastObject.id")).to.eql 2

  describe ".findAll", ->
    beforeEach ->
      server.respondWith "GET", "/klasses.json",
        [ 200, { "Content-Type": "application/json" },
          JSON.stringify({klasses: [{id: 1, name: "1"}, {id: 20, name: "20"}]})
        ]

    it 'returns list of records', ->
      records = klass.findAll()
      expect(records.get("isLoading")).to.be.true
      Em.run -> server.respond()
      expect(records.get("isLoading")).to.be.false
      expect(records.mapProperty("id")).to.have.members [1,20]
      expect(records.mapProperty("name")).to.have.members ["1", "20"]

    it 'performs identity map with existing records in the cache', ->
      Em.run -> klass.loadAll [{id: 1}, {id: 2}]
      records = klass.findAll()
      Em.run -> server.respond()
      expect(records.get('length')).to.eql 2
      expect(records.mapProperty("id")).to.have.members [1,20]
      expect(records.mapProperty("id")).not.to.have.members [2]
      expect(records.mapProperty("name")).to.have.members ["1", "20"]

  describe ".findResource", ->
    beforeEach ->
      server.respondWith "GET", "/klasses/1.json",
        [ 200, { "Content-Type": "application/json" },
          JSON.stringify({id: 1, name: "1"})
        ]

    context "when the resource is cached", ->
      beforeEach ->
        Em.run -> klass.loadAll [{id: 1}, {id: 2}]

      it 'returns the resource and performs an request on the fly', ->
        expect(klass._data.get("length")).to.eql 2
        record = klass.findResource 1
        expect(klass._data.get("length")).to.eql 2
        expect(record.get("id")).to.eql 1
        expect(record.get("name")).to.be.undefined
        Em.run -> server.respond()
        expect(record.get("name")).to.eql "1"

    context "when the resource is not cached", ->
      it 'returns an empty record and patched it with an ajax request', ->
        record = klass.findResource 1
        expect(record.get("id")).to.be.undefined
        expect(record.get("name")).to.be.undefined
        Em.run -> server.respond()
        expect(klass._data.get("length")).to.eql 1
        expect(record.get("name")).to.eql "1"
        expect(record.get("id")).to.eql 1
