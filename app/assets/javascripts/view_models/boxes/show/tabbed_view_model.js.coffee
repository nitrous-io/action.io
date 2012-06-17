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

  closeTab: (tab) =>
    if tab.active()
      tab.active(false)
      index = @tabs.indexOf(tab)
      index = (index - 1)
      index = 0 if index < 0
      if prevTab = @tabs()[index]
        this.activateTab(prevTab)
    @tabs.remove(tab)

  __destroy: ->
    kb.utils.release(tab) for tab in @tabs()
    super()

