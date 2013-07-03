AIO.N2oBonusController = Em.ObjectController.extend
  content: null
  bonusInfo: null

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

  _autoRedeemChromeAppBonus: (->
    chromeAppBonusRedeemed = @get('content.chrome_app') != null
    if !chromeAppBonusRedeemed && this.isChromeAppInstalled()
      this.notifyChromeAppInstallation()
  ).observes 'content.chrome_app'
