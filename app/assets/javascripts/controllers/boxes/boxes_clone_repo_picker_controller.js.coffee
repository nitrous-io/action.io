AIO.BoxesCloneRepoPickerController = Em.ObjectController.extend
  content: null
  errors: null

  eligibleBoxes: (->
    Em.ArrayProxy.create
      content: _.filter AIO.get('router.boxesController').get('content'), (box) =>
        state = box.get('state')
        if box.get('ownBox')
          state == 'running' || state == 'stopped'
        else
          state == 'running'
  ).property 'AIO.router.boxesController.content.@each.state'

  ineligibleBoxes: (->
    allBoxes = AIO.get('router.boxesController').get('content')
    _.difference(allBoxes, @get('eligibleBoxes.content'))
  ).property 'AIO.router.boxesController.content.@each.state'

  newRecord: ->
    repository = AIO.Repository.create()
    repository.set 'clone_url', AIO.get('currentUser.intendedCloneRepoURL')
    @set 'content', repository

  cloneIntoNewBox: ->
    AIO.get('router').transitionTo 'boxes.new'

  cloneIntoExistingBox: (box) ->
    switch box.get('state')
      when 'running'
        @cloneAndRedirect(box)
      when 'stopped'
        box.start().done (json) =>
          @cloneAndRedirect()

  cloneAndRedirect: (box) ->
    @set 'content.box_id', box.id
    @get('content').identify (json) =>
      if json.errors?.base?[0]
        @set 'errors', json.errors?.base?[0]
        return
      if json.repository?.id?
        AIO.get('router').transitionTo 'boxes.cloning_repo', id: box.get('id'), repo_id: json.repository.id
