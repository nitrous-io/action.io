AIO.BoxesProvisioningController = Em.ObjectController.extend
  needs: ['boxes']

  findById: (id) ->
    @get('controllers.boxes').findResource id, (box) =>
      @set 'content', box

  redirectToIdeWhenRunning: (->
    if AIO.get('router.currentPath') == 'root.boxes.provisioning' && content = @get 'content'
      if content.get('state') == 'running'
        Em.run.next ->
          AIO.get('router').transitionTo 'boxes.ide', id: content.get 'id'
  ).observes 'content.state'

