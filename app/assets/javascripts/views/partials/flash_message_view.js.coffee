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
    @$('.alert').removeClass('in').addClass('in')

  hide: ->
    @$('.alert').removeClass('in')

  didClickClose: ->
    @set 'message', null
    false
