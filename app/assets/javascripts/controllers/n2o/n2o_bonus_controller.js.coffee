AIO.N2oBonusController = Em.ObjectController.extend
  content: null
  bonusInfo: null
  composeTweetDialog: null
  buyN2oDialog: null

  reload: ->
    $.ajax(
      type: 'GET'
      dataType: 'json'
      url: '/bonus'
    ).done (json) =>
      if attrs = json.bonus
        @get('content')?.setProperties attrs

  isChromeAppInstalled: ->
    window.chrome?.app?.isInstalled

  notifyChromeAppInstallation: ->
    $.ajax(
      type: 'PUT'
      url: '/user/chrome_app_installed'
    ).always =>
      this.reload()

  followOnTwitter: ->
    $.ajax(type: 'PUT', url: '/bonus/twitter_follow')
    @get('content').set 'twitter_follow', Date.now()

  composeTweet: ->
    @set 'composeTweetDialog', AIO.ComposeTweetDialog.create()

  buyN2o: ->
    @set 'buyN2oDialog', AIO.BuyN2oDialog.create()

  sendTweet: (message) ->
    $.ajax(type: 'PUT', url: '/bonus/send_tweet', data: { message: message })
    @get('content').set 'tweet_sent', Date.now()

  _autoRedeemChromeAppBonus: (->
    chromeAppBonusRedeemed = @get('content.chrome_app') != null
    if !chromeAppBonusRedeemed && this.isChromeAppInstalled()
      this.notifyChromeAppInstallation()
  ).observes 'content.chrome_app'
