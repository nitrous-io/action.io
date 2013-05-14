AIO.CollabMessage = Em.Object.extend
  username: null
  message: null
  messageType: null

  isChatMessage: (->
    messageType = @get 'messageType'
    (messageType == undefined) || (messageType == AIO.CollabMessage.chat)
  ).property 'messageType'

  messageFragment: (->
    messageType = @get 'messageType'
    if messageType == AIO.CollabMessage.fileOpen
      "has open"
    else if messageType == AIO.CollabMessage.collabMode
      "enabled collab mode on"
  ).property 'messageType'

  filePath: (->
    messageType = @get('messageType')
    if  (messageType == AIO.CollabMessage.fileOpen) || (messageType == AIO.CollabMessage.collabMode)
      @get 'message'
  ).property 'messageType', 'message'

AIO.CollabMessage.chat = 1
AIO.CollabMessage.fileOpen = 2
AIO.CollabMessage.collabMode = 3
