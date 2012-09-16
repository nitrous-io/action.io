AIO.BoxesProvisioningView = Em.View.extend
  templateName: 'templates/boxes/provisioning'
  classNames: ['app_page']
  elementId: 'boxes_provisioning_view'

  title: 'Provisioning'
  titleInterval: null

  didInsertElement: ->
    @_super()
    titleCounter = 0
    @set 'titleInterval', window.setInterval =>
      @set 'title', 'Provisioning' + '...'.substring(0, ++titleCounter % 4)
    , 1000

  willDestroyElement: ->
    @_super()
    window.clearInterval @get 'titleInterval'
    @set 'titleInterval', null

  redirectToIdeWhenRunning: (->
    if box = @get 'controller.content'
      if box.get('state') == 'running'
        Ember.run.schedule 'sync', ->
          AIO.get('router').transitionTo 'boxes.ide', id: box.get 'id'
  ).observes 'controller.content.state'

