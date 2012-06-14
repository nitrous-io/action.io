class AIO.IDERouter extends AIO.Router
  routes:
    ''                   : 'root'
    'boxes'              : 'boxes#index'
    'boxes/new'          : 'boxes#new'

  'root' : ->
    this.navigate 'boxes', trigger: true, replace: true

  'boxes#index' : ->
    vm = AIO.vm.boxesIndexViewModel ||= new AIO.BoxesIndexViewModel(AIO.c.boxes)
    vm.view = new AIO.BoxesIndexView
    this.setCurrentViewModel(vm)

  'boxes#new': ->
    box = AIO.newBox ||= new AIO.Box
    vm = AIO.vm.boxesNewViewModel ||= new AIO.BoxesNewViewModel(box)
    vm.view = new AIO.BoxesNewView
    this.setCurrentViewModel(vm)

