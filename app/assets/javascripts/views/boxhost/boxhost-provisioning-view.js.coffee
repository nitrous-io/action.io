App.BoxhostProvisioningView = Em.View.extend
  templateName: 'templates/boxhost/provisioning'
  classNames: ['app_page', 'provisioning']
  elementId: 'boxhost_provisioning_view'

  title: 'Setting Up Your Boxes'
  titleInterval: null

  didInsertElement: ->
    @_super()
    App.util.mixpanel 'Viewed Boxhost Provisioning page'

    titleCounter = 0
    @set 'titleInterval', window.setInterval(=>
      @set 'title', 'Setting Up Your Boxes' + '...'.substring(0, ++titleCounter % 4)
    , 1000)

  willDestroyElement: ->
    @_super()
    window.clearInterval @get 'titleInterval'
    @set 'titleInterval', null
