AIO.IntroAppsView = Em.View.extend
  templateName: 'templates/intro/intro_apps'
  elementId: 'intro_apps_view'
  classNames: ['app_page', 'intro']

  didClickNextScreen: ->
    box = @get 'controller.content'
    state = box.get 'state'

    switch state
      when 'running'
        AIO.get('router').transitionTo 'boxes.ide', id: box.get 'id'
      when 'provisioning'
        box.set 'expanded', true
        AIO.get('router').transitionTo 'boxes.index'
      when 'failed'
        box.set 'expanded', true
        AIO.get('router').transitionTo 'boxes.index'
        Em.run.next ->
          AIO.set 'flashMessage', { type: 'error', text: 'Sorry, there seems to be a problem creating your box. Please try again later or in a different region.' }
      else
        AIO.get('router').transitionTo 'boxes.index'
