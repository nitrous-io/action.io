#= require spec_helper

Foo = AIO.Resource.extend
  resourceUrl: '/foos'
  resourceName: 'foo'
  bar: null

describe 'AIO.ResourceController', ->
  controller = null

  beforeEach ->
    controller = AIO.ResourceController.create
      resourceType: Foo

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

