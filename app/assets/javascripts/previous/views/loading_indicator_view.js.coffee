class aio.views.LoadingIndicatorView extends Backbone.View
  template: JST['previous/templates/loading_indicator_view']
  id: 'loading_indicator_wrapper'

  initialize: ->
    @loadingRequestsCount = 0

  render: ->
    @$el.html(this.template())
    @$el.hide()
    this

  show: ->
    @loadingRequestsCount += 1
    @$el.fadeIn()

  hide: ->
    @$el.fadeOut() if (@loadingRequestsCount -= 1) == 0

