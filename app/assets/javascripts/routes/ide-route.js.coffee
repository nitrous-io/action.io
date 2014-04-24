App.IdeRoute = Em.Route.extend
  activate: ->
    # warn the user before actually unload the window. This is helpful to
    # prevent mis-click close tab / cmd + w
    $(window).bind 'beforeunload.ide', ->
      "Remember to save all changes before closing the editor"

  deactivate: ->
    $(window).unbind 'beforeunload.ide'
