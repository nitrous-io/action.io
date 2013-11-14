AIO.IntroCreateBoxView = AIO.BoxFormView.extend
  templateName: 'templates/intro/intro_create_box'
  elementId: 'intro_create_box_view'
  classNames: ['app_page', 'intro', 'new']

  didClickCreateBox: (event) ->
    controller = @get('controller')
    controller.set 'afterSavePage', 'intro.n2o'
    @_super(event)

  didClickNextScreen: ->
    this.didClickCreateBox()
