AIO.Panel = klass = Em.Object.extend
  active: false
  focused: false
  title: null
  id: null

klass.reopen
  isPanel: true
  clean: true
