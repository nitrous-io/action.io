class AIO.TabbedViewModel extends AIO.ViewModel
  constructor: (model) ->
    super(model)
    @tabs = ko.observableArray([])

  newTab: (tab) ->
    @tabs.push(tab)
    this.activateTab(tab)

  activateTab: (tab) =>
    for t in @tabs()
      t.active(false) if t != tab
    tab.active(true)

  currentTab: =>
    for t in @tabs()
      return t if t.active()

  closeTab: (tab) =>
    index = null
    if tab.active()
      tab.active(false)
      index = @tabs.indexOf(tab)
      index = (index - 1)
      index = 0 if index < 0
    @tabs.remove(tab)
    if index? && prevTab = @tabs()[index]
      this.activateTab(prevTab)
    kb.utils.release(tab)

  __destroy: ->
    kb.utils.release(tab) for tab in @tabs()
    @tabs.removeAll()
    super()

