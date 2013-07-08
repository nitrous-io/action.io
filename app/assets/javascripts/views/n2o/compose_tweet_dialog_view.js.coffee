AIO.ComposeTweetDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/n2o/compose_tweet_dialog'
  elementId: 'compose_tweet_dialog_view'
  contentBinding: 'controller.composeTweetDialog' # N2oBonusController

  message: null

  messageInvalid: (->
    unless message = @get('message')
      return true

    message_length = message.length
    !(message_length > 0 && message_length < 60)
  ).property 'message'

  didClickSendTweet: ->
    unless @get 'messageInvalid'
      @get('controller').sendTweet @get('message')
      this.hide()

AIO.ComposeTweetDialogTextField = Em.TextField.extend
  insertNewline: (event) ->
    @get('parentView').didClickSendTweet()
