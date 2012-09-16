Foo = AIO.Resource.extend
  resourceUrl: '/foos'
  resourceName: 'foo'
  bar: null

describe 'AIO.ResourceController', ->
  controller = retVal = null

  doAction = ->
    retVal = controller.findResource 123

  beforeEach ->
    controller = AIO.ResourceController.create
      resourceType: Foo

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

      it 'passes the resource to done callback', (done) ->
        resource = controller.get 'content.0'
        retVal.done (r) ->
          expect(r).to.equal resource
          done()

    context 'when a resource with same id already exists', ->
      existingResource = null

      beforeEach ->
        controller.set 'content', [existingResource = Foo.create id: 123, bar: 'qux']
        doAction()
        respond()

      it 'updates the resource in content array', ->
        content = controller.get 'content'
        resource = content.objectAt 0
        expect(content).to.have.length 1
        expect(resource).to.equal existingResource
        expect(resource.get 'id').to.equal 123
        expect(resource.get 'bar').to.equal 'baz'

      it 'passes the resource to done callback', (done) ->
        resource = controller.get 'content.0'
        retVal.done (r) ->
          console.log r
          console.log resource
          expect(r).to.equal resource
          done()

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

