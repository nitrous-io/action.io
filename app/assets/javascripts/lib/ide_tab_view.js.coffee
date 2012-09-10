AIO.IdeTabView = Em.View.extend
  tabs: []
  modelClass: Em.Object

  makeTabActive: (tab) ->
    unless tab.get 'active'
      tabs = @get 'tabs'
      tabs.forEach (t) ->
        t.set('active', t == tab)

  removeTab: (tab) ->
    tabs = @get 'tabs'
    len = tabs.length
    idx = tabs.indexOf tab
    if tab.get 'active'
      tab.set('active', false)
      nextIdx = if idx < (len - 1)
        idx + 1
      else if idx == (len - 1)
        idx - 1
      nextIdx = 0 if nextIdx < 0
      if nextIdx != idx
        tabs.objectAt(nextIdx)?.set('active', true)
    tabs.removeObject(tab)

  didClickTab: (event) ->
    tab = event.context
    this.makeTabActive(tab)

  didClickClose: (event) ->
    event.stopPropagation()
    tab = event.context
    this.removeTab(tab)

  didClickNew: ->
    newTab = @get('modelClass').create()
    @get('tabs').pushObject(newTab)
    this.makeTabActive(newTab)

