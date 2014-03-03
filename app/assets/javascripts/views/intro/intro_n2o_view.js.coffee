AIO.IntroN2oView = AIO.BoxesControlView.extend
  templateName: 'templates/intro/intro_n2o'
  elementId: 'intro_n2o_view'
  classNames: ['app_page', 'intro']

  memoryBinding: 'controller.content.memory'
  storageBinding: 'controller.content.storage'

  didClickNextScreen: ->
    box = @get 'controller.content'
    AIO.get('router').transitionTo 'intro.apps', id: box.get 'id'
