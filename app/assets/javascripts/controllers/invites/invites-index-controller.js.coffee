App.InvitesIndexController = Em.ArrayController.extend
  content: (->
    App.Invite.all()
  ).property()

  sortProperties: ['created_at']
  sortAscending: false

  newInvite: null

  sendInvite: ->
    @get('newInvite')?.save().then =>
      @set 'newInvite', App.Invite.create()
