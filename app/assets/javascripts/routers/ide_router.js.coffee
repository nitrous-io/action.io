class AIO.IDERouter extends AIO.Router
  routes:
    ''                       : 'root'
    'boxes'                  : 'boxes#index'
    'boxes/new'              : 'boxes#new'
    'boxes/:id/provisioning' : 'boxes#provisioning'
    'boxes/:id'              : 'boxes#show'

  'root' : ->
    this.redirectTo 'boxes'

  'boxes#index' : ->
    view = new AIO.BoxesIndexView
    this.setCurrentView(view)
    vm = new AIO.BoxesIndexViewModel(AIO.c.boxes)
    this.setCurrentViewAndViewModel(view, vm)

  'boxes#new': ->
    if AIO.c.boxes.filter((box) -> box.get('id') && box.get('state') != 'terminated').length > 0
      this.redirectTo 'boxes'
      return
    view = new AIO.BoxesNewView
    vm = new AIO.BoxesNewViewModel
    this.setCurrentViewAndViewModel(view, vm)

  'boxes#provisioning': (id) ->
    box = AIO.c.boxes.get(id)
    if boxState = box.get('state') != 'provisioning'
      this.redirectTo "boxes/#{id}"
      return
    view = new AIO.BoxesProvisioningView
    vm = new AIO.BoxesProvisioningViewModel(box)
    this.setCurrentViewAndViewModel(view, vm)

  'boxes#show': (id) ->
    box = AIO.c.boxes.get(id)
    if (boxState = box.get('state')) == 'provisioning'
      this.redirectTo "boxes/#{id}/provisioning"
      return
    else if boxState != 'running'
      console.log boxState
      this.redirectTo 'boxes'
      return
    AIO.c.files.reset()
    AIO.c.documents.reset()
    view = new AIO.BoxesShowView
    vm = new AIO.BoxesShowViewModel(box)
    this.setCurrentViewAndViewModel(view, vm)

