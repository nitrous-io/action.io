App.IntroAppsView = Em.View.extend
  templateName: 'templates/intro/intro-apps'
  elementId: 'intro_apps_view'
  classNames: ['app_page', 'intro']

  didClickNextScreen: ->
    box = @get 'controller.content'
    state = box.get 'state'

    switch state
      when 'running'
        App.get('router').transitionTo 'boxes.ide', id: box.get 'id'
      when 'provisioning'
        box.set 'expanded', true
        App.get('router').transitionTo 'boxes.index'
      when 'failed'
        box.set 'expanded', true
        App.get('router').transitionTo 'boxes.index'
        Em.run.next ->
          App.set 'flashMessage', { type: 'error', text: 'Sorry, there seems to be a problem creating your box. Please try again later or in a different region.' }
      else
        App.get('router').transitionTo 'boxes.index'
