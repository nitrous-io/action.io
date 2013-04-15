AIO.IdeTabViewMixin = Em.Mixin.create
  didClickTab: (tab) ->
    @get('controller').makeTabActive tab

  didClickClose: (tab) ->
    @get('controller').removeTab tab

  didClickNew: ->
    @get('controller').createTab()

