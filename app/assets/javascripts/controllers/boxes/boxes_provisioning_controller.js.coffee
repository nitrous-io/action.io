AIO.BoxesProvisioningController = Em.ObjectController.extend
  redirectToIdeWhenRunning: (->
    if AIO.get('router.currentPath') == 'root.boxes.provisioning' && content = @get 'content'
      if content.get('state') == 'running'
        Em.run.next ->
          AIO.get('router').transitionTo 'boxes.ide', id: content.get 'id'
  ).observes 'content.state'

