AIO.FlashMessageView = Em.View.extend
  templateName: 'templates/partials/flash_message'
  elementId: 'flash_messages'
  messageBinding: 'AIO.flashMessage'

  showOrHide: (->
    if @get 'message'
      this.show()
    else
      this.hide()
  ).observes 'message'

  show: ->
    @$('div.alert').removeClass 'hide'
    @$('div.alert').addClass 'slide'

  hide: ->
    @$('div.alert').addClass 'hide'
    @$('div.alert').removeClass 'slide'

  didClickClose: ->
    AIO.set 'flashMessage', null
    this.hide()
