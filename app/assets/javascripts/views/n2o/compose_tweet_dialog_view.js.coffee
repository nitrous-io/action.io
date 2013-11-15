AIO.ComposeTweetDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/n2o/compose_tweet_dialog'
  elementId: 'compose_tweet_dialog_view'
  contentBinding: 'controller.composeTweetDialog' # N2oBonusController

  message: null

  didInsertElement: ->
    @set 'message', "I can code Ruby/Python/Node.JS & Go apps on Nitrous.IO! Sign Up now and get 250MB free space: #{AIO.get 'currentUser.referralLinkFullURL'}"

  messageInvalid: (->
    messageLength = @get 'messageLength'
    !(messageLength > 0 && messageLength <= 140)
  ).property 'message'

  messageLength: (->
    unless message = @get('message')
      return 0

    return message.length
  ).property 'message'

  didClickSendTweet: ->
    unless @get 'messageInvalid'
      @get('controller').sendTweet @get('message')
      this.hide()

AIO.ComposeTweetDialogTextArea = Em.TextArea.extend
  insertNewline: (event) ->
    @get('parentView').didClickSendTweet()
