AIO.BoxesProvisioningController = Em.ObjectController.extend
  redirectBasedOnState: (->
    if AIO.get('router.currentPath') == 'root.boxes.provisioning' && content = @get 'content'
      if content.get('state') == 'running'
        Em.run.next ->
          if content.get('repository_to_clone')
            AIO.get('router').transitionTo 'boxes.cloning_repo', id: content.get 'id'
          else
            AIO.get('router').transitionTo 'boxes.ide', id: content.get 'id'
      if content.get('state') == 'failed'
        Em.run.next ->
          AIO.get('router').transitionTo 'boxes.index'
          AIO.set 'flashMessage', { type: 'error', text: 'Sorry, there seems to be a problem creating your box. Please try again later or in a different region.' }
  ).observes 'content.state'

