App.BoxesCloningRepoController = Em.ObjectController.extend
  content: null
  repository: null

  redirectBasedOnState: (->
    if App.get('router.currentPath') == 'root.boxes.cloning_repo' && content = @get 'content'
      if content.get('state') == 'running'
        Em.run.next ->
          if content.get('last_added_repository_id')
            App.get('router').transitionTo 'boxes.ide_with_repo', id: content.get('id'), repo_id: content.get('last_added_repository_id')
          else
            App.get('router').transitionTo 'boxes.ide', id: content.get 'id'
      if content.get('state') == 'failed'
        Em.run.next ->
          App.set('router.boxesCloneRepoPickerController.errors', "This does not look like a Github repository")
          App.get('router').transitionTo 'boxes.clone_repo_picker'
  ).observes 'content.state'
