AIO.PusherController = Em.Controller.extend
  initialize: (pusherKey) ->
    if AIO.get('environment') == 'development'
      Pusher.log = (message) -> console.log message

    currentUser = AIO.get 'router.applicationController.currentUser'

    @set 'pusher', pusher = new Pusher pusherKey
    @set 'channel', channel = pusher.subscribe "private-user-#{currentUser.get 'id'}"

    channel.bind 'aio:box_updated', (data) ->
      console.log 'box updated'
      if box = AIO.get('router.boxesController').findById(data.id)
        console.log box
        box.setProperties data

