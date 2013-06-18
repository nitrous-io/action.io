AIO.N2OView = Em.View.extend
  templateName: 'templates/partials/n2o'
  classNames: ['n2o_view']

  freeN2OBinding: Em.Binding.oneWay 'AIO.currentUser.free_n2o'
  maxN2OBinding: Em.Binding.oneWay 'AIO.currentUser.max_n2o'

  didInsertElement: ->
    @_super()
    this._updateBarWidth()

  _updateBarWidth: (->
    freeN2O = @get('freeN2O') ? 0
    maxN2O  = @get('maxN2O')  ? 0
    @$('.bar')?.css 'width', "#{freeN2O / maxN2O * 100}%"
  ).observes 'freeN2O', 'maxN2O'
