App.BoxesCloningRepoView = Em.View.extend
  templateName: 'templates/boxes/cloning-repo'
  classNames: ['app_page']
  elementId: 'boxes_cloning_repo_view'

  title: 'Cloning'
  titleInterval: null

  didInsertElement: ->
    @_super()
    titleCounter = 0
    @set 'titleInterval', window.setInterval(=>
      @set 'title', 'Cloning' + '...'.substring(0, ++titleCounter % 4)
    , 1000)

  willDestroyElement: ->
    @_super()
    window.clearInterval @get 'titleInterval'
    @set 'titleInterval', null

  didClickIDE: ->
    App.get('router').transitionTo 'boxes.ide', id: @get('controller.content.id')
