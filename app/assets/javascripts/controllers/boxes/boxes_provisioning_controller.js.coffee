AIO.BoxesProvisioningController = Em.ObjectController.extend
  redirectToIdeWhenRunning: (->
    if content = @get('content')
      if content.get('state') == 'running'
        this.transitionToRoute 'boxes.ide', content
  ).observes 'content.state'
