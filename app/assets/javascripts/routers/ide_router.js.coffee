class AIO.IDERouter extends AIO.Router
  routes:
    ''                   : 'root'
    'boxes'              : 'boxes#index'

  'root' : ->
    this.navigate 'boxes', trigger: true, replace: true

  'boxes#index' : ->
    vm = AIO.vm.boxesIndexViewModel ||= new AIO.BoxesIndexViewModel(AIO.c.boxes)
    vm.view = new AIO.BoxesIndexView
    this.setCurrentViewModel(vm)

