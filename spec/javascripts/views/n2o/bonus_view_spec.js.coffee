describe 'AIO.N2oBonusView', ->
  view = null

  beforeEach ->
    view = AIO.N2oBonusView.create()

  afterEach ->
    view.destroy()

  describe '#isUsingChrome', ->
    origChrome = null

    beforeEach ->
      origChrome = window.chrome
      window.chrome = {}

    afterEach ->
      window.chrome = origChrome

    context 'when chrome.app is defined', ->
      beforeEach ->
        window.chrome.app = {}

      it 'returns true', ->
        expect(view.get('isUsingChrome')).to.be.true

    context 'when chrome.app is not defined', ->
      it 'returns false', ->
        expect(view.get('isUsingChrome')).to.be.false

  describe '#installChromeApp', ->
    beforeEach ->
      window.chrome ?= { webstore: { install: -> } }
      view.set 'controller', { reload: (->), notifyChromeAppInstallation: -> }
      sinon.stub window.chrome.webstore, 'install'
      sinon.stub view.controller, 'notifyChromeAppInstallation'

    afterEach ->
      window.chrome.webstore.install.restore()

    doAction = ->
      view.installChromeApp()

    context 'when the installation is successful', ->
      beforeEach ->
        window.chrome.webstore.install.callsArg 1
        view.installChromeApp()

      it 'calls notifyChromeAppInstallation on controller', ->
        expect(view.controller.notifyChromeAppInstallation).to.have.been.called
