AIO.BoxesCloningRepoController = Em.ObjectController.extend
  content: null

  cloneURL: (->
    @get('repository_clone_url') || @get('repositoryToClone.clone_url')
  ).property 'repository_clone_url', 'repositoryToClone.clone_url'

  redirectBasedOnRepoState: (->
    if AIO.get('router.currentPath') == 'root.boxes.cloning_repo' && content = @get 'content'
      switch content.get('repositoryToClone.state')
        when 'cloned'
          Em.run.next ->
            AIO.get('router').transitionTo 'boxes.ide', id: content.get 'id'
        when 'failed'
          console.log 'cloning failed'
          # TODO Show the error message and a button for user to go to IDE anyways.
  ).observes 'content.repositoryToClone.state'
