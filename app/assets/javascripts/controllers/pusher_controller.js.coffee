AIO.PusherController = Em.Controller.extend
  initialize: (pusherKey) ->
    if AIO.get('environment') == 'development'
      Pusher.log = (message) -> console.log message

    currentUser = AIO.get 'router.applicationController.currentUser'

    @set 'pusher', pusher = new Pusher pusherKey
    @set 'channel', channel = pusher.subscribe "private-user-#{currentUser.get 'id'}"

    channel.bind 'aio:box_updated', (json) ->
      json = json[AIO.Box::get 'resourceName']
      if box = AIO.get('router.boxesController').findById json.id
        box.deserialize json

        trackingData =
          boxTemplate: box.get('boxTemplate.name')
          region: box.get('region.name')

        AIO.util.mixpanel "box:#{box.get('state')}", trackingData

