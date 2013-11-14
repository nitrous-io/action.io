AIO.IntroCreateBoxView = AIO.BoxFormView.extend
  templateName: 'templates/intro/intro_create_box'
  elementId: 'intro_create_box_view'
  classNames: ['app_page', 'intro', 'new']

  didClickNextScreen: ->
    this.didClickCreateBox()
