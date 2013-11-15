AIO.IntroN2oView = AIO.BoxesControlView.extend
  templateName: 'templates/intro/intro_n2o'
  elementId: 'intro_n2o_view'
  classNames: ['app_page', 'intro']

  memoryBinding: 'controller.content.memory'
  storageBinding: 'controller.content.storage'

  didClickNextScreen: ->
    box = @get 'controller.content'
    state = box.get 'state'

    switch state
      when 'running'
        AIO.get('router').transitionTo 'boxes.ide', id: box.get 'id'
      when 'provisioning'
        AIO.get('router').transitionTo 'boxes.index'
      when 'failed'
        AIO.get('router').transitionTo 'boxes.index'
        Em.run.next ->
          AIO.set 'flashMessage', { type: 'error', text: 'Sorry, there seems to be a problem creating your box. Please try again later or in a different region.' }
      else
        AIO.get('router').transitionTo 'boxes.index'
