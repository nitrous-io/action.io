class AIO.MenuItemViewModel extends AIO.ViewModel
  constructor: (name, macKey, windowsKey, linkOrAction) ->
    super()
    @name = ko.observable(name)
    @key = ko.observable(if AIO.isMac() then macKey else windowskey)
    @href = ko.observable(null)
    if _.isFunction(linkOrAction)
      @action = linkOrAction
    else if _.isString(linkOrAction)
      @action = null
      @href(linkOrAction)

  action: ->
    AIO.showAlertDialog('Feature Coming Soon', 'This feature is coming soon!')

