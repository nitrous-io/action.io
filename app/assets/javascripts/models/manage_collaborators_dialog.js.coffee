AIO.ManageCollaboratorsDialog = Em.ArrayProxy.extend
  content: null # array of AIO.Collaborator
  boxBinding: Em.Binding.oneWay 'AIO.router.ideController.content'

  newCollaboratorUsername: ''
  saving: false

  init: ->
    @_super()
    @set 'content', []

  fetch: ->
    box = @get 'box'
    AIO.Collaborator.fetch box.get('id'), (err, models) =>
      @set 'content', models

  addCollaborator: (done) ->
    username = $.trim @get('newCollaboratorUsername')
    @set 'newCollaboratorUsername', username
    if username.length > 0
      @set 'saving', true
      box = @get 'box'
      content = @get 'content'
      AIO.Collaborator.add box.get('id'), username, (err, model) =>
        @set 'saving', false
        if model && !err
          content.addObject model
          @set 'newCollaboratorUsername', ''
        done()

  removeCollaborator: (collaborator) ->
    box = @get 'box'
    content = @get 'content'
    collaborator.remove box.id, (err) ->
      if !err
        content.removeObject collaborator

