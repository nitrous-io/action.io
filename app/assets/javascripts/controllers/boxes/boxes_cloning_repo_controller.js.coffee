AIO.BoxesCloningRepoController = Em.ObjectController.extend
  content: null
  repository: null

  redirectBasedOnRepoState: (->
    if AIO.get('router.currentPath') == 'root.boxes.cloning_repo' && content = @get 'content'
      switch @get('repository.state')
        when 'cloned'
          Em.run.next ->
            AIO.get('router').transitionTo 'boxes.ide', id: content.get 'id'
        when 'identified'
          if @get('repository').supported()
            this.startClone()
          else
            this.returnToPicker("This does not look like a Git or Mercurial repository.")
        when 'failed'
          # TODO Show the error message and a button for user to go to IDE anyways.
  ).observes 'repository.state'

  startClone: ->
    content = @get 'content'
    content.cloneRepo (@get 'repository'), (e) =>
      if e?.base?[0]
        this.returnToPicker(e.base[0])

  returnToPicker: (errorMessage) ->
    AIO.set('router.boxesCloneRepoPickerController.errors', errorMessage)
    AIO.get('router').transitionTo 'boxes.clone_repo_picker'
