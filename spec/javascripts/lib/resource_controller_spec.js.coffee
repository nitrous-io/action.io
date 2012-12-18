Foo = AIO.Resource.extend
  resourceUrl: '/foos'
  resourceName: 'foo'
  bar: null

describe 'AIO.ResourceController', ->
  controller = null

  beforeEach ->
    controller = AIO.ResourceController.create
      resourceType: Foo
      jsonRoot: 'foo'

  describe '#findResource', ->
    retVal = cbSpy = null

    beforeEach ->
      cbSpy = sinon.spy()

    doAction = (callback=cbSpy) ->
      retVal = controller.findResource 123, callback

    it 'returns a jQuery ajax promise', ->
      doAction()
      expect(retVal.done).to.be.a 'function'
      expect(retVal.fail).to.be.a 'function'
      expect(retVal.always).to.be.a 'function'

    it 'does not yet add the object to content array', ->
      doAction()
      expect(controller.get 'content').to.have.length 0

    context 'when the request succeeds', ->
      respond = ->
        server.respondWith 'GET', '/foos/123', [
          200
          { 'Content-Type': 'application/json; charset=utf-8' }
          '{"foo": {"id": 123, "bar": "baz"}}'
        ]
        server.respond()

      context 'when a resource with same id does not exist', ->
        beforeEach ->
          doAction()
          respond()

        it 'adds the resource to content array', ->
          content = controller.get 'content'
          resource = content.objectAt 0
          expect(content).to.have.length 1
          expect(resource).to.be.an.instanceof Foo
          expect(resource.get 'id').to.equal 123
          expect(resource.get 'bar').to.equal 'baz'

        it 'makes a callback with the resource', ->
          resource = controller.get 'content.0'
          expect(cbSpy).to.have.been.calledWith resource

      context 'when a resource with same id already exists', ->
        existingResource = null

        beforeEach ->
          controller.set 'content', [existingResource = Foo.create id: 123, bar: 'qux']

        context 'before response', ->
          it 'makes a callback immediately', (done) ->
            doAction (resource) ->
              expect(resource).to.equal existingResource
              done()

        context 'after response', ->
          beforeEach ->
            doAction()
            respond()

          it 'updates the resource in content array', ->
            content = controller.get 'content'
            resource = content.objectAt 0
            expect(content).to.have.length 1
            expect(resource).to.equal existingResource
            expect(resource.get 'id').to.equal 123
            expect(resource.get 'bar').to.equal 'baz'

          it 'makes a callback with the resource', ->
            resource = controller.get 'content.0'
            expect(cbSpy).to.have.been.calledWith resource

    context 'when the request fails', ->
      beforeEach ->
        doAction()
        server.respondWith 'GET', '/foos/123', [
          404
          { 'Content-Type': 'application/json; charset=utf-8' }
          '{"error": "not found"}'
        ]
        server.respond()

      it 'does not add the resource to content array', ->
        expect(controller.get 'content').to.have.length 0

  describe '#build', ->
    it 'create a resource from a json representation', ->
      resource = controller.build bar: "foo"
      expect(resource.get("bar")).to.eql("foo")

  describe '#buildAll', ->
    it 'creates a list of resources from a json representation', ->
      resources = controller.buildAll foo: [{id: 1, bar: "foo"}, {id: 2, bar: "foobar"}]
      expect(resources[0].get("id")).to.eql(1)
      expect(resources[0].get("bar")).to.eql("foo")
      expect(resources[1].get("id")).to.eql(2)
      expect(resources[1].get("bar")).to.eql("foobar")

  describe '#insertResources', ->
    resources = null

    beforeEach ->
      obj1 = Foo.create().deserialize(id: 1, bar: "foo")
      obj2 = Foo.create().deserialize(id: 2, bar: "foobar")
      resources = [obj1, obj2]

    it 'inserts a list of resources into contents', ->
      controller.loadResources resources
      expect(controller.get("content.0.bar")).to.eql "foo"
      expect(controller.get("content.1.bar")).to.eql "foobar"

    it 'updates the resources that already inside contents', ->
      controller.addObject Foo.create().deserialize(id: 2, bar: "oldfoobar")
      controller.loadResources resources
      expect(controller.get("content.1.id")).to.eql 2
      expect(controller.get("content.1.bar")).to.eql "foobar"

    it 'does not insert resource with empty id', ->
      controller.addObject Foo.create().deserialize(id: 3, bar: "foobar")
      controller.loadResources resources
      expect(controller.findProperty("id", 3)).to.be.undefined
