class AIO.PusherController
  constructor: (pusherKey) ->
    if AIO.environment == 'development'
      Pusher.log = (message) -> console.log(message)

    @pusher = new Pusher(pusherKey)
    @channel = @pusher.subscribe "private-user-#{AIO.currentUser.get('id')}"

    @channel.bind 'aio:box_updated', (data) ->
      box = AIO.c.boxes.get(data.id)
      box.set(data)

