AIO.ChatMessage = Em.Object.extend
  username: null
  message: null
  eventType: null

  eventDescription: (->
    eventType = @get 'eventType'
    if eventType == "fileOpen"
      "has open"
  ).property 'eventType'

  filePath: (->
    if @get('eventType')
      @get 'message'
  ).property 'eventType', 'message'

