AIO.InvitesCollection = Em.ArrayProxy.extend
  content: null

AIO.CollaboratorsCollection = Em.ArrayProxy.extend
  content: null

AIO.ManageCollaboratorsDialog = Em.Object.extend
  collaborators: null # array of AIO.Collaborator
  invites: null # instance of AIO.InvitesCollection
  boxBinding: Em.Binding.oneWay 'AIO.router.ideController.content'

  newCollaboratorIdentifier: ''
  errorMessage: null
  saving: false

  init: ->
    @_super()
    @set 'collaborators', []
    @set 'invites', []

  fetch: ->
    box = @get 'box'
    AIO.Collaborator.fetch box.get('id'), (err, models) =>
      @set 'collaborators', AIO.CollaboratorsCollection.create(content: Em.A(models))
    AIO.Invite.fetch box.get('id'), (err, models) =>
      @set 'invites', AIO.InvitesCollection.create(content: Em.A(models))

  addCollaborator: (done) ->
    identifier = $.trim @get('newCollaboratorIdentifier')
    @set 'newCollaboratorIdentifier', identifier
    return unless identifier.length > 0

    @set 'saving', true
    box = @get 'box'
    collaborators = @get 'collaborators'
    invites = @get 'invites'

    $.ajax(
      type: 'POST'
      dataType: 'json'
      data:
        identifier: identifier
      url: "/boxes/#{box.id}/collaborators"
    ).done((json) =>
      if json?.collaborator?
        model = AIO.Collaborator.create json.collaborator
        collaborators.addObject model
      else if json?.invite?
        model = AIO.Invite.create json.invite
        invites.addObject model
      @set 'newCollaboratorIdentifier', null
    ).fail((json) =>
      if json.status == 404
        @set 'errorMessage', "Failed to create new collaborator"
    ).always =>
      @set 'saving', false
      done()

  removeCollaborator: (collaborator) ->
    box = @get 'box'
    collaborators = @get 'collaborators'
    collaborator.remove box.id, (err) ->
      if !err
        collaborators.removeObject collaborator
