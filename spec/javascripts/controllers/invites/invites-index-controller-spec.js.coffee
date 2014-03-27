describe 'AIO.InvitesIndexController', ->
  controller = null

  beforeEach ->
    AIO.Invite.all().set 'content', Em.A()
    controller = AIO.InvitesIndexController.create(newInvite: AIO.Invite.create())

  describe '#sendInvite', ->
    doAction = (email) ->
      controller.set 'newInvite.email', email
      controller.sendInvite()

    context 'successfully saving the invite', ->
      respond  = ->
        server.respondWith 'POST', '/invites.json', [
          201
          { 'Content-Type': 'application/json; charset=utf-8' }
          '{"invite": {"id": 123, "email": "test@gmail.com", "state": "activated", "created_at": "2013-06-10T09:13:45Z" }}'
        ]
        server.respond()

      beforeEach ->
        currentUser = AIO.get 'currentUser'

        doAction 'test@gmail.com'
        respond()

      it 'adds the invite to content', ->
        expect(controller.get 'content.length').to.equal 1
        expect(controller.get 'content.firstObject').to.be.an.instanceOf AIO.Invite

    context 'failing to save the invite', ->
      respond  = ->
        server.respondWith 'POST', '/invites.json', [
          422
          { 'Content-Type': 'application/json; charset=utf-8' }
          '{"errors": { "email": ["some error"] }}'
        ]
        server.respond()

      beforeEach ->
        controller.set 'content', []
        currentUser = AIO.get 'currentUser'

        doAction 'test@gmail.com'
        respond()

      it 'does not add the invite to content', ->
        expect(controller.get 'content').to.be.empty
