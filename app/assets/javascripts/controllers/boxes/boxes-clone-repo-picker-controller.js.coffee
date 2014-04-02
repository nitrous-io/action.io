App.BoxesCloneRepoPickerController = Em.ObjectController.extend
  content: null
  errors: null

  eligibleBoxes: (->
    Em.ArrayProxy.create
      content: App.get('boxes').filter (box) =>
        state = box.get('state')
        if box.get('ownBox')
          state == 'running' || state == 'stopped'
        else
          state == 'running'
  ).property 'App.boxes.@each.state'

  ineligibleBoxes: (->
    _.difference App.get('boxes.content'), @get('eligibleBoxes.content')
  ).property 'App.boxes.@each.state'

  newRecord: ->
    repository = App.Repository.create()
    repository.set 'clone_url', App.get('currentUser.intendedCloneRepoURL')
    @set 'content', repository

  cloneIntoNewBox: ->
    App.get('router').transitionTo 'boxes.new'

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
        App.get('router').transitionTo 'boxes.cloning_repo', id: box.get('id'), repo_id: json.repository.id
