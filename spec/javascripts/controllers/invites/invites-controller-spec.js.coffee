describe 'App.InvitesController', ->
  describedClass = App.InvitesController
  controller = null

  beforeEach ->
    App.Invite.all().set 'content', Em.A()
    controller = describedClass.create(newInvite: App.Invite.create(), content: App.Invite.all())

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
        currentUser = App.get 'currentUser'

        doAction 'test@gmail.com'
        respond()

      it 'adds the invite to content', ->
        expect(controller.get 'content.length').to.equal 1
        expect(controller.get 'content.firstObject').to.be.an.instanceOf App.Invite

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
        currentUser = App.get 'currentUser'

        doAction 'test@gmail.com'
        respond()

      it 'does not add the invite to content', ->
        expect(controller.get 'content').to.be.empty
