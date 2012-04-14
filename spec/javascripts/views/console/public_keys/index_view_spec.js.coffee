describe 'aio.views.console.public_keys.IndexView', ->
  view = null

  before ->
    aio.app.publicKeys = new aio.collections.PublicKeys
    view = new aio.views.console.public_keys.IndexView(collection: aio.app.publicKeys)
    $('#jasmine-fixtures').append(view.render().$el)

  context 'when "Add SSH Key" button is clicked', ->
    before ->
      spyOn(window, 'navigateTo')
      $addKeyButton = $findOne('#add_key_button')
      $addKeyButton.click()

    it 'navigates to new public key view', ->
      expect(window.navigateTo).toHaveBeenCalledWith('#public_keys/new')

