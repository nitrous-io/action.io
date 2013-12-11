AIO.N2oBonusView = Em.View.extend
  templateName: 'templates/n2o/bonus'
  classNames: ['app_page', 'n2o_bonus_view']

  isUsingChrome: (->
    window.chrome?.app?
  ).property()

  installChromeApp: ->
    if window.chrome?.webstore?
      url = $('link[rel=chrome-webstore-item]').attr('href')
      window.chrome.webstore.install url, (o) =>
        if controller = @get('controller')
          controller.notifyChromeAppInstallation()

  followOnTwitter: ->
    @get('controller').followOnTwitter()

  composeTweet: ->
    @get('controller').composeTweet()
