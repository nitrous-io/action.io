App.IdeTabViewMixin = Em.Mixin.create
  didClickTab: (tab) ->
    @get('controller').makeTabActive tab

  didClickClose: (tab) ->
    event.stopPropagation()
    controller = @get 'controller'
    @get('controller').removeTab tab

  didClickNew: ->
    @get('controller').createTab()

