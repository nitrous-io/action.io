describe 'aio.views.LoadingIndicatorView', ->
  view = null

  before ->
    view = new aio.views.LoadingIndicatorView
    $('#jasmine-fixtures').append(view.render().$el)

  it 'is hidden by default', ->
    expect(view.$el).not.toBeVisible()

  it 'has its loading requests count set to 0', ->
    expect(view.loadingRequestsCount).toEqual 0

  describe '#show', ->
    before ->
      view.show()

    it 'reveals the view', ->
      expect(view.$el).toBeVisible()

    it 'increments the loading requests count by 1', ->
      expect(view.loadingRequestsCount).toEqual 1
      view.show()
      expect(view.loadingRequestsCount).toEqual 2

  describe '#hide', ->
    context 'when the loading requests count is > 1', ->
      before ->
        view.show()
        view.show()
        expect(view.loadingRequestsCount).toEqual 2
        view.hide()

      it 'decrements the loading requests count by 1', ->
        expect(view.loadingRequestsCount).toEqual 1

      it 'does not hide the view', ->
        expect(view.$el).toBeVisible()

    context 'when the loading requests count is 1', ->
      before ->
        view.show()
        expect(view.loadingRequestsCount).toEqual 1
        view.hide()

      it 'decrements the loading requests count by 1', ->
        expect(view.loadingRequestsCount).toEqual 0

      it 'hides the view', ->
        expect(view.$el).not.toBeVisible()

