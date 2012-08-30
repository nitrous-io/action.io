class AIO.MenuViewModel extends AIO.ViewModel
  constructor: (name, items=[]) ->
    super()
    @name = ko.observable(name)
    @items = ko.observableArray(items)

  __destroy: ->
    kb.utils.release(item) for item in @items()
    @items.removeAll()
    super()

