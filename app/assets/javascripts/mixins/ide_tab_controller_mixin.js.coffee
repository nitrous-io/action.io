AIO.IdeTabControllerMixin = Em.Mixin.create
  modelClass: Em.required()

  activeTab: (->
    content = @get 'content'
    content.findProperty 'active', true
  ).property 'content.@each.active'

  hasNoTab: (->
    content = @get 'content'
    !content || content.length == 0
  ).property 'content', 'content.length'

  addTab: (tab) ->
    @get('content').pushObject tab
    this.makeTabActive tab

  createTab: (attrs={}) ->
    tab = @get('modelClass').create attrs
    this.addTab tab

  makeTabActive: (tab) ->
    unless tab.get 'active'
      content = @get 'content'
      content.forEach (t) ->
        t.set 'active', t == tab

  removeTab: (tab) ->
    tab = @get 'activeTab' unless tab
    content = @get 'content'
    len = content.length
    idx = content.indexOf tab
    if tab.get 'active'
      tab.set 'active', false
      nextIdx = if idx < (len - 1)
        idx + 1
      else if idx == (len - 1)
        idx - 1
      nextIdx = 0 if nextIdx < 0
      if nextIdx != idx
        content.objectAt(nextIdx)?.set 'active', true
    content.removeObject tab

