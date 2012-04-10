describe 'aio.views.console.SidebarView', ->
  view = null

  before ->
    view = new aio.views.console.SidebarView
    $('#jasmine-fixtures').append(view.render().$el)

  context 'when "New Box" button is clicked', ->
    before ->
      spyOn(window, 'navigateTo')
      $newBoxButton = $findOne('#new_box_button').removeAttr('disabled')
      $newBoxButton.click()

    it 'navigates to new box view', ->
      expect(window.navigateTo).toHaveBeenCalledWith('#boxes/new')

