AIO.BoxesCloneRepoPickerController = Em.ObjectController.extend
  content: null

  eligibleBoxes: (->
    Em.ArrayProxy.create
      content: _.filter AIO.get('router.boxesController').get('content'), (box) =>
        state = box.get('state')
        state == 'running' || state == 'stopped'
  ).property 'AIO.router.boxesController.content.@each.state'

  newRecord: ->
    repository = AIO.Repository.create()
    repository.set 'clone_url', AIO.get('currentUser.intendedCloneRepoURL')
    @set 'content', repository

  cloneIntoNewBox: ->
    AIO.get('router').transitionTo 'boxes.new'

  cloneIntoExistingBox: ->
    box = @get('content.box')
    if !box
      errors =
        box_id: ['Please select a box.']
      @get('content').set 'errors', errors
      return

    switch box.get('state')
      when 'running'
        @cloneAndRedirect()
      when 'stopped'
        box.start().done (json) =>
          @cloneAndRedirect()

  cloneAndRedirect: ->
    box = @get('content.box')
    box.cloneRepo @get('content'), ->
      AIO.get('router').transitionTo 'boxes.cloning_repo', id: box.get('id')
