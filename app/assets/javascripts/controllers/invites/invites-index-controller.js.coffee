AIO.InvitesIndexController = Em.ArrayController.extend
  content: (->
    AIO.Invite.all()
  ).property()

  sortProperties: ['created_at']
  sortAscending: false

  newInvite: null

  sendInvite: ->
    @get('newInvite')?.save().then =>
      @set 'newInvite', AIO.Invite.create()
