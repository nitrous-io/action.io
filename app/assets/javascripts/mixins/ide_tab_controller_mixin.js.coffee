AIO.IdeTabControllerMixin = Em.Mixin.create
  modelClass: Em.required()

  tabCount: (->
    @get('content').length
  ).property 'content.length'

  activeTab: (->
    content = @get 'content'
    content.findProperty 'active', true
  ).property 'content.@each.active'

  activeTabIndex: (->
    content = @get 'content'
    activeTab = @get 'activeTab'
    content.indexOf activeTab
  ).property 'activeTab'

  hasNoTab: (->
    content = @get 'content'
    !content || content.length == 0
  ).property 'content', 'content.length'

  nextTab: (->
    activeTabIndex = @get 'activeTabIndex'
    tabCount = @get 'tabCount'
    index = (activeTabIndex + 1) % tabCount
    @get "content.#{index}"
  ).property 'activeTabIndex', 'tabCount'

  previousTab: (->
    activeTabIndex = @get 'activeTabIndex'
    tabCount = @get 'tabCount'
    index = (((activeTabIndex - 1) % tabCount) + tabCount) % tabCount
    @get "content.#{index}"
  ).property 'activeTabIndex', 'tabCount'

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
      Em.run.next ->
        content.forEach (t) ->
          t.set 'focused', t == tab

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

  makeNextTabActive: ->
    if @get('tabCount') > 1
      nextTab = @get 'nextTab'
      this.makeTabActive nextTab

  makePreviousTabActive: ->
    if @get('tabCount') > 1
      previousTab = @get 'previousTab'
      this.makeTabActive previousTab

