class AIO.Router extends Backbone.Router
  initialize: (options) ->
    @$rootEl = $(options.rootEl || 'body')

  setCurrentViewModel: (viewModel) ->
    @$html ||= $('html')

    if @currentHTMLClassName
      @$html.removeClass(@currentHTMLClassName)
      @currentHTMLClassName = null

    if @currentViewModel?.view
      ko.cleanNode(@currentViewModel.view.el)
      @currentViewModel.view = null

    @currentViewModel = viewModel
    if view = viewModel.view
      @currentHTMLClassName = _.map(view.className.split(' '),
        (className) -> '_' + className
      ).join(' ')
      @$html.addClass(@currentHTMLClassName)
      @$rootEl.empty().append(view.render().$el)
      ko.applyBindings(viewModel, @$rootEl[0])

