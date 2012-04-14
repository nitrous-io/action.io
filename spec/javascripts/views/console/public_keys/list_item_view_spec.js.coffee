describe 'aio.views.console.public_keys.ListItemView', ->
  view = null

  before ->
    model = new aio.models.PublicKey(id: 123)
    aio.app.publicKeys = new aio.collections.PublicKeys
    aio.app.publicKeys.reset([model])
    view = new aio.views.console.public_keys.ListItemView(model: model)
    $('#jasmine-fixtures').append(view.render().$el)

  context 'when "Edit" button is clicked', ->
    before ->
      spyOn(window, 'navigateTo')
      $findOne('#edit_public_key_button').click()

    it 'navigates to edit public key view', ->
      expect(window.navigateTo).toHaveBeenCalledWith('#public_keys/123/edit')

  context 'when "Delete" button is clicked', ->
    request = null

    before ->
      jasmine.Ajax.useMock()
      spyOn(window, 'confirm')

    doAction = ->
      $findOne('#delete_public_key_button').click()
      request = mostRecentAjaxRequest()

    it 'shows a confirm dialog', ->
      doAction()
      expect(window.confirm).toHaveBeenCalled()

    context 'when the user confirms', ->
      before ->
        window.confirm.andReturn(true)
        doAction()

      it 'sends a DELETE request to /public_keys', ->
        expect(request.method).toEqual 'DELETE'
        expect(request.url).toEqual '/public_keys/123'

      it 'removes the model from the public keys collection', ->
        request.response
          status: 204
        expect(aio.app.publicKeys).not.toContain view.model

    context 'when the user cancels', ->
      before ->
        window.confirm.andReturn(false)
        doAction()

      it 'does not send a DELETE request', ->
        expect(request).toBeNull()

      it 'does not removes the model from the public keys collection', ->
        expect(aio.app.publicKeys).toContain view.model

