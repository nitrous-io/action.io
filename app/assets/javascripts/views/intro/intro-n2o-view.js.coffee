#= require ../boxes/boxes-control-with-name-generation-view

App.IntroN2oView = App.BoxesControlWithNameGenerationView.extend
  templateName: 'templates/intro/intro-n2o'
  elementId: 'intro_n2o_view'
  classNames: ['app_page', 'intro']

  memoryBinding: 'controller.content.memory'
  storageBinding: 'controller.content.storage'

  didClickNextScreen: ->
    box = @get 'controller.content'
    App.get('router').transitionTo 'intro.apps'
