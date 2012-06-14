class AIO.Router extends Backbone.Router
  initialize: (options) ->
    @$rootEl = $(options.rootEl || 'body')

  setCurrentViewModel: (viewModel) ->
    if @currentViewModel?.view
      ko.cleanNode(@currentViewModel.view.el)
      @currentViewModel.view = null

    @currentViewModel = viewModel
    if viewModel.view
      @$rootEl.empty().append(@currentViewModel.view.render().$el)
      ko.applyBindings(@currentViewModel, @$rootEl[0])

