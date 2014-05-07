App.IdeRoute = Em.Route.extend
  box_id: null

  activate: ->
    # warn the user before actually unload the window. This is helpful to
    # prevent mis-click close tab / cmd + w
    $(window).bind 'beforeunload.ide', ->
      "Remember to save all changes before closing the editor"

  deactivate: ->
    $(window).unbind 'beforeunload.ide'

  beforeModel: (transition) ->
    @set 'box_id', transition.params.box?.box_id

  actions:
    willTransition: (transition) ->
      if window.confirm('You will lose unsaved work if you move away from the editor. Are you sure you want to leave?')
        return true
      else
        App.Router.router.replaceURL "/boxes/#{@get('box_id')}/ide"
        transition.abort()
