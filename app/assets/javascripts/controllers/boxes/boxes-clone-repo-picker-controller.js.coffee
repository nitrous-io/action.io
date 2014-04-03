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
    box_id = box.get('id')
    @set 'content.box_id', box_id

    repo = @get('content')
    repo.identify (json) =>
      if repo.get('state') == 'identified'
        $.ajax(
          url:  "/boxes/#{box_id}/clone_repo"
          type: 'PUT'
          data:
            repository:
              scm: repo.get('scm')
              state: repo.get('state')
              clone_url: repo.get('clone_url')
        ).done((json) ->
          App.get('router').transitionTo 'boxes.cloning_repo', id: box.get('id'), repo_id: json.box.repository_id_to_clone
        ).fail (e) =>
          response = $.parseJSON e.responseText
          errorMessage = response.errors?.base?[0]
          @set 'errors', errorMessage
      else
        @set 'errors', 'does not look like a valid Github repository'
