AIO.IdeCollaborationPaneView = Em.View.extend
  templateName: 'templates/ide/collaboration_pane'
  elementId: 'ide_collaboration_pane_view'
  chatFieldText: null
  hiddenBinding: 'AIO.router.ideLayoutController.collaborationPaneHidden'
  classNameBindings: ['hidden']

  didClickHideChat: ->
    @set 'hidden', true

  didClickSend: ->
    if message = @get 'chatFieldText'
      @get('controller').sendChatMessage(message)
      @set 'chatFieldText', null

  scrollChatToBottom: ->
    @$('.chat').scrollTop this._chatMaxScroll()

  _hiddenDidChange: (->
    Em.run.scheduleOnce 'afterRender', this, 'scrollChatToBottom'
  ).observes 'hidden'

  _chatMaxScroll: ->
    $chat = @$('.chat')
    $messages = $('ul', $chat)
    Math.max 0, ($messages.height() - $chat[0].clientHeight)

  _scrollChatToBottomIfAlreadyAtBottom: (->
    $chat = @$('.chat')
    if $chat.length > 0
      Em.run.scheduleOnce 'afterRender', this, 'scrollChatToBottom'
  ).observes 'controller.messages.length'

  _consoleHeightDidChange: (->
    consoleHeight = AIO.get 'router.ideLayoutController.consoleHeight'
    @$().css 'paddingBottom', (consoleHeight + 4)
  ).observes 'AIO.router.ideLayoutController.consoleHeight'

AIO.IdeCollaborationPaneOnlineUsersButton = Em.View.extend
  tagName: 'button'
  classNames: ['btn', 'ide_collaboration_pane_online_users_button']
  attributeBindings: ['title']

  mouseEnter: ->
    $('#collaboration_pane .popover').show()

  mouseLeave: ->
    $('#collaboration_pane .popover').fadeOut(100)

AIO.IdeCollaborationPaneTextField = Em.TextField.extend
  insertNewline: ->
    @get('parentView')?.didClickSend()
