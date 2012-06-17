class AIO.Router extends Backbone.Router
  initialize: (options) ->
    @$rootEl = $(options.rootEl || 'body')

  setCurrentViewAndViewModel: (view, viewModel) ->
    this.setCurrentView(view)
    this.setCurrentViewModel(viewModel)

  setCurrentView: (view) ->
    if @currentView
      ko.cleanNode(@currentView.el)
      @$rootEl.empty()

    @currentView = view

    @$html ||= $('html')

    if @currentHTMLClassName
      @$html.removeClass(@currentHTMLClassName)
      @currentHTMLClassName = null

    if @currentHTMLClassName = view.htmlClassName
      @$html.addClass(@currentHTMLClassName)

    @$rootEl.append(view.render().$el)

  setCurrentViewModel: (viewModel) ->
    if @currentViewModel
      kb.utils.release(@currentViewModel)

    @currentViewModel = viewModel

    ko.applyBindings(viewModel, @$rootEl[0])

