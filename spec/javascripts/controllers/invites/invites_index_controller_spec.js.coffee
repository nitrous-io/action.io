describe 'AIO.InvitesIndexController', ->
  controller = null

  beforeEach ->
    controller = AIO.InvitesIndexController.create()

  describe '#sendInvite', ->
    doAction = (email) ->
      controller.sendInvite email

    context 'successfully saving the invite', ->
      respond  = ->
        server.respondWith 'POST', '/invites', [
          200
          { 'Content-Type': 'application/json; charset=utf-8' }
          '{"invite": {"id": 123, "email": "test@gmail.com", "state": "activated", "created_at": "2013-06-10T09:13:45Z" }}'
        ]
        server.respond()

      beforeEach ->
        controller.set 'content', []
        currentUser = AIO.get 'currentUser'

        doAction 'test@gmail.com'
        respond()

      it 'sets saving to false', ->
        expect(controller.get 'saving').to.equal false

      it 'sets the error to null', ->
        expect(controller.get 'error').to.equal null

      it 'adds the invite to content', ->
        content = controller.get 'content'
        resource = content.objectAt 0
        expect(content).to.have.length 1
        expect(resource).to.be.an.instanceof AIO.Invite


    context 'failing to save the invite', ->
      respond  = ->
        server.respondWith 'POST', '/invites', [
          422
          { 'Content-Type': 'application/json; charset=utf-8' }
          '{"error": "some error"}'
        ]
        server.respond()

      beforeEach ->
        controller.set 'content', []
        currentUser = AIO.get 'currentUser'

        doAction 'test@gmail.com'
        respond()

      it 'sets saving to false', ->
        expect(controller.get 'saving').to.equal false

      it 'sets the error', ->
        expect(controller.get 'error').to.equal 'some error'

      it 'does not add the invite to content', ->
        expect(controller.get 'content').to.be.empty

