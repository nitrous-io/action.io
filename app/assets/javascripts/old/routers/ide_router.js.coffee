class AIO.IDERouter extends AIO.Router
  routes:
    ''                       : 'root'
    'boxes'                  : 'boxes#index'
    'boxes/new'              : 'boxes#new'
    'boxes/:id/provisioning' : 'boxes#provisioning'
    'boxes/:id'              : 'boxes#show'

  'root' : ->
    if $.browser.msie && parseFloat($.browser.version) < 10.0
      window.alert('Internet Explorer version 9.0 and below are not supported. Proceed at your own risk.')
      return

    this.redirectTo 'boxes'

  'boxes#index' : ->
    reset()
    view = new AIO.BoxesIndexView
    vm = new AIO.BoxesIndexViewModel(AIO.c.boxes)
    this.setCurrentViewAndViewModel(view, vm)

  'boxes#new': ->
    reset()
    if AIO.c.boxes.filter((box) -> box.get('id') && box.get('state') != 'terminated').length > 0
      this.redirectTo 'boxes'
      return
    view = new AIO.BoxesNewView
    vm = new AIO.BoxesNewViewModel
    this.setCurrentViewAndViewModel(view, vm)

  'boxes#provisioning': (id) ->
    reset()
    box = AIO.c.boxes.get(id)
    if boxState = box.get('state') != 'provisioning'
      this.redirectTo "boxes/#{id}"
      return
    view = new AIO.BoxesProvisioningView
    vm = new AIO.BoxesProvisioningViewModel(box)
    this.setCurrentViewAndViewModel(view, vm)

  'boxes#show': (id) ->
    reset()
    box = AIO.c.boxes.get(id)
    if (boxState = box.get('state')) == 'provisioning'
      this.redirectTo "boxes/#{id}/provisioning"
      return
    else if boxState != 'running'
      this.redirectTo 'boxes'
      return
    view = new AIO.BoxesShowView
    vm = new AIO.BoxesShowViewModel(box)
    this.setCurrentViewAndViewModel(view, vm)

reset = ->
  AIO.events.reset()
  AIO.callbacks = {}

