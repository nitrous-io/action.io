AIO.BoxesProvisioningController = Em.ObjectController.extend
  redirectToIdeWhenRunning: (->
    if @get('content.state') == 'running'
      Em.run.next =>
        this.transitionToRoute 'ide', @get('content')
  ).observes 'content.state'
