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
    @$('.alert').slideDown()

  hide: (cb) ->
    if cb
      @$('.alert').slideUp cb

  didClickClose: ->
    this.hide ->
      AIO.set 'flashMessage', null
