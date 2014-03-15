AIO.N2oBonusController = Em.ObjectController.extend
  content: null
  bonusInfo: null
  composeTweetDialog: null
  isIntro: false
  hideBusinessSurveyBonus: true

  toggleBusinessSurvey: (->
    if @get('business_survey') || AIO.get('currentUser.hasCompany')
      @set 'hideBusinessSurveyBonus', false
  ).observes 'business_survey', 'AIO.currentUser.hasCompany'

  reload: ->
    $.ajax(
      type: 'GET'
      dataType: 'json'
      url: '/bonus'
    ).done (json) =>
      if json && json.bonus && json.bonus.id
        @get('content')?.load json.bonus.id, json.bonus
        if !@get('business_survey')
          user = AIO.get('currentUser')
          user.fetchCompany() unless user.get('hasCompany')

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

  sendTweet: (message) ->
    $.ajax(type: 'PUT', url: '/bonus/send_tweet', data: { message: message })
    @get('content').set 'tweet_sent', Date.now()

  _autoRedeemChromeAppBonus: (->
    chromeAppBonusRedeemed = @get('content.chrome_app') != null
    if !chromeAppBonusRedeemed && this.isChromeAppInstalled()
      this.notifyChromeAppInstallation()
  ).observes 'content.chrome_app'
