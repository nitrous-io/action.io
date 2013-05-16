AIO.CollabMessage = Em.Object.extend
  username: null
  message: null
  messageType: null

  chatMessage: (->
    messageType = @get 'messageType'
    console.log messageType
    (messageType == undefined) || (messageType == AIO.CollabMessage.chat)
  ).property 'messageType'

  messageDescription: (->
    messageType = @get 'messageType'
    if messageType == AIO.CollabMessage.fileOpen
      "has open"
    else if messageType == AIO.CollabMessage.collabMode
      "enabled collab mode on"
  ).property 'messageType'

  filePath: (->
    if @get('messageType')
      @get 'message'
  ).property 'messageType', 'message'

AIO.CollabMessage.chat = 1
AIO.CollabMessage.fileOpen = 2
AIO.CollabMessage.collabMode = 3
