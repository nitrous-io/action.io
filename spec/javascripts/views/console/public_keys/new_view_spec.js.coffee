describe 'aio.views.console.public_keys.NewView', ->
  view = null

  before ->
    aio.app.publicKeys = new aio.collections.PublicKeys
    view = new aio.views.console.public_keys.NewView(collection: aio.app.publicKeys)
    $('#jasmine-fixtures').append(view.render().$el)

  describe 'filling up the form', ->
    key = 'ssh-rsa myAwesomeKey test@action.io'

    before ->
      $('#public_key_name').val('my awesome key').change()
      $('#public_key_key').val(key).change()

    it 'has its model bound to the changes in the form', ->
      expect(view.model.get('name')).toEqual 'my awesome key'
      expect(view.model.get('key')).toEqual key

    context 'upon clicking add key button', ->
      request = null

      before ->
        jasmine.Ajax.useMock()
        $('#console-public_keys-new .submit').click()
        request = mostRecentAjaxRequest()

      it 'sends a POST request to /public_keys', ->
        expect(request.method).toEqual 'POST'
        expect(request.url).toEqual '/public_keys'
        params = JSON.parse(request.params)
        expect(params.name).toEqual 'my awesome key'
        expect(params.key).toEqual key

      it 'adds the newly created public key to the public keys collection', ->
        request.response
          status: 201
          responseText: JSON.stringify(view.model)
        expect(aio.app.publicKeys).toContain view.model

      context 'upon receiving a successful response by the server', ->
        before ->
          spyOn(window, 'navigateTo')
          request.response
            status: 201
            responseText: JSON.stringify(view.model)

        it 'navigates to #public_keys', ->
          expect(window.navigateTo).toHaveBeenCalledWith('#public_keys')

