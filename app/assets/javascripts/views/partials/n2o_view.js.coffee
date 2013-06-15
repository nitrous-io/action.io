AIO.N2OView = Em.View.extend
  templateName: 'templates/partials/n2o'
  classNames: ['n2o_view']

  usedN2OBinding: Em.Binding.oneWay 'AIO.currentUser.used_n2o'
  maxN2OBinding: Em.Binding.oneWay 'AIO.currentUser.max_n2o'

  _updateBarWidth: (->
    usedN2O = @get('usedN2O') ? 0
    maxN2O  = @get('maxN2O')  ? 0
    @$('.bar').css 'width', "#{usedN2O / maxN2O * 100}%"
  ).observes 'usedN2O', 'maxN2O'
