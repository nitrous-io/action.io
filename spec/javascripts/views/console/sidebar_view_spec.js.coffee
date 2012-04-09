describe 'aio.views.console.SidebarView', ->
  view = null

  before ->
    view = new aio.views.console.SidebarView
    $('#jasmine-fixtures').append(view.render().$el)

  describe '#render', ->
    it 'renders', ->
      expect(view.$el).not.toBeEmpty()

  context 'when "New Box" button is clicked', ->
    before ->
      spyOn(window, 'navigateTo')
      $newBoxButton = $findOne('#new_box_button').removeAttr('disabled')
      $newBoxButton.click()

    it 'navigates to #new_box', ->
      expect(window.navigateTo).toHaveBeenCalledWith('#new_box')

