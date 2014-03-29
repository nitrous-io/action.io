App.BoxesProvisioningController = Em.ObjectController.extend
  redirectBasedOnState: (->
    if App.get('router.currentPath') == 'root.boxes.provisioning' && content = @get 'content'
      if content.get('state') == 'running'
        Em.run.next ->
          App.get('router').transitionTo 'boxes.ide', id: content.get 'id'
      if content.get('state') == 'failed'
        Em.run.next ->
          App.get('router').transitionTo 'boxes.index'
          App.set 'flashMessage', { type: 'error', text: 'Sorry, there seems to be a problem creating your box. Please try again later or in a different region.' }
  ).observes 'content.state'

