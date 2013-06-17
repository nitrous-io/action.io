AIO.InvitesIndexController = Em.ObjectController.extend
  contentBinding: 'AIO.router.invitesController'
  saving: false
  error: null

  sendInvite: (email) ->
    invite = AIO.Invite.create email: email
    @set 'saving', true
    @set 'error', null
    invite.saveResource()
      .fail (e) =>
        if e.status == 422
          @set 'error', $.parseJSON(e.responseText).error
      .done =>
        @get('content').addObject invite
        if currentUser = AIO.get 'router.applicationController.currentUser'
          currentUser.decrementProperty 'available_invites'
      .always =>
        @set 'saving', false
