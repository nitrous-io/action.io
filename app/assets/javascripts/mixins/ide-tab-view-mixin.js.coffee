App.IdeTabViewMixin = Em.Mixin.create
  didClickTab: (event) ->
    tab = event.context
    @get('controller').makeTabActive tab

  didClickClose: (event) ->
    event.stopPropagation()
    tab = event.context
    controller = @get 'controller'
    @get('controller').removeTab tab

  didClickNew: ->
    @get('controller').createTab()

