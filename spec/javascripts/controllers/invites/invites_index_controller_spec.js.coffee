describe 'AIO.InvitesIndexController', ->
  controller = null

  beforeEach ->
    controller = AIO.InvitesIndexController.create()

  describe '#sendInvite', ->
    doAction = (email) ->
      controller.sendInvite email

    context 'sucessfully saving the invite', ->
      respond  = ->
        server.respondWith 'POST', '/invites', [
          200
          { 'Content-Type': 'application/json; charset=utf-8' }
          '{"invite": {"id": 123, "email": "test@example.com", "state": "activated", "created_at": "2013-06-10T09:13:45Z" }}'
        ]
        server.respond()

      beforeEach ->
        controller.set 'content', []
        currentUser = AIO.get 'currentUser'
        currentUser.set 'available_invites', 10

        doAction 'test@example.com'
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

      it 'decrements available invite count of the current user', ->
        expect(AIO.get 'currentUser.available_invites').to.equal 9

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
        currentUser.set 'available_invites', 10

        doAction 'test@example.com'
        respond()

      it 'sets saving to false', ->
        expect(controller.get 'saving').to.equal false

      it 'sets the error', ->
        expect(controller.get 'error').to.equal 'some error'

      it 'does not add the invite to content', ->
        expect(controller.get 'content').to.be.empty

      it 'does not decrement available invite count of the current user', ->
        expect(AIO.get 'currentUser.available_invites').to.equal 10
