describe 'aio.views.console.IndexView', ->
  view = null

  before ->
    view = new aio.views.console.IndexView
    $('#jasmine-fixtures').append(view.render().$el)

  describe '#render', ->
    it 'renders', ->
      expect(view.$el).not.toBeEmpty()

