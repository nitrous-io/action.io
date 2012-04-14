describe 'aio.views.console.public_keys.EditView', ->
  view = null

  before ->
    model = new aio.models.PublicKey(id: 123, name: 'my old key', key: 'ssh-rsa oldKey test@action.io')
    aio.app.publicKeys = new aio.collections.PublicKeys
    aio.app.publicKeys.reset([model])
    view = new aio.views.console.public_keys.EditView(model: model)
    $('#jasmine-fixtures').append(view.render().$el)

  describe 'filling up the form', ->
    key = 'ssh-rsa myAwesomeKey test@action.io'

    before ->
      $('#public_key_name').val('my awesome key').change()
      $('#public_key_key').val(key).change()

    it 'has its model bound to the changes in the form', ->
      expect(view.model.get('name')).toEqual 'my awesome key'
      expect(view.model.get('key')).toEqual key

    context 'upon clicking save button', ->
      request = null

      before ->
        jasmine.Ajax.useMock()
        $('#console-public_keys-edit .submit').click()
        request = mostRecentAjaxRequest()

      it 'sends a PUT request to /public_keys/123', ->
        expect(request.method).toEqual 'PUT'
        expect(request.url).toEqual '/public_keys/123'
        params = JSON.parse(request.params)
        expect(params.name).toEqual 'my awesome key'
        expect(params.key).toEqual key

      context 'upon receiving a successful response by the server', ->
        before ->
          spyOn(window, 'navigateTo')
          request.response
            status: 200
            responseText: JSON.stringify(view.model)

        it 'navigates to #public_keys', ->
          expect(window.navigateTo).toHaveBeenCalledWith('#public_keys')

