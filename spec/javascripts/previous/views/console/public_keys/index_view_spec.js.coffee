describe 'aio.views.console.public_keys.IndexView', ->
  view = null

  renderView = ->
    $('#jasmine-fixtures').empty().append(view.render().$el)

  before ->
    aio.app.currentUser = new aio.models.User
    aio.app.publicKeys = new aio.collections.PublicKeys
    view = new aio.views.console.public_keys.IndexView(collection: aio.app.publicKeys)

  context 'when "Add SSH Key" button is clicked', ->
    before ->
      renderView()
      spyOn(window, 'navigateTo')
      $findOne('#add_key_button').click()

    it 'navigates to new public key view', ->
      expect(window.navigateTo).toHaveBeenCalledWith('#public_keys/new')

  describe 'github public key import', ->
    context 'when the user has authenticated with GitHub', ->
      before ->
        spyOn(aio.app.currentUser, 'hasGitHub').andReturn true
        renderView()

      it 'shows "Import from GitHub" button', ->
        $importButton = $findOne('#import_from_github_button')
        expect($importButton).toBeVisible()
        expect($importButton).not.toBeDisabled()

      context 'when "Import from GitHub" button is clicked', ->
        before ->
          spyOn(view.collection, 'importGitHubKeys')
          $findOne('#import_from_github_button').click()

        it 'disables the button', ->
          expect($('#import_from_github_button')).toBeDisabled()

        it 'calls importFromGitHub method on the public keys collection', ->
          expect(view.collection.importGitHubKeys).toHaveBeenCalled()

    context 'when the user did not authenticate with GitHub', ->
      before ->
        spyOn(aio.app.currentUser, 'hasGitHub').andReturn false
        renderView()

      it 'disables "Import from GitHub" button', ->
        $importButton = $findOne('#import_from_github_button')
        expect($importButton).toBeVisible()
        expect($importButton).toBeDisabled()

