describe 'AIO.N2oBonusController', ->
  controller = bonus = null

  beforeEach ->
    bonus = AIO.Bonus.create()
    controller = AIO.N2oBonusController.create content: bonus

  describe '#reload', ->
    attrs =
      id: 1
      invite_friends: "2013-01-19T00:00:00Z"
      github:         "2013-02-18T00:00:00Z"
      twitter:        "2013-03-17T00:00:00Z"
      facebook:       "2013-04-16T00:00:00Z"
      linkedin:       "2013-05-15T00:00:00Z"

    beforeEach ->
      server.respondWith 'GET', '/bonus', [
        200
        { 'Content-Type': 'application/json; charset=utf-8' }
        JSON.stringify({bonus: attrs})
      ]
      controller.reload()
      server.respond()

    it 'fetches and reloads bonus object', ->
      content = controller.get 'content'
      expect(content.get 'id').to.equal attrs.id
      expect(content.get 'invite_friends').to.equal attrs.invite_friends
      expect(content.get 'github'  ).to.equal attrs.github
      expect(content.get 'twitter' ).to.equal attrs.twitter
      expect(content.get 'facebook').to.equal attrs.facebook
      expect(content.get 'linkedin').to.equal attrs.linkedin

  describe '#isChromeAppInstalled', ->
    origChrome = null

    beforeEach ->
      origChrome = window.chrome
      window.chrome = { app: { isInstalled: false } }

    afterEach ->
      window.chrome = origChrome

    context 'if chrome app is not installed', ->
      it 'returns false', ->
        expect(controller.isChromeAppInstalled()).to.be.false

    context 'if chrome app is installed', ->
      beforeEach ->
        window.chrome = { app: { isInstalled: true } }

      it 'returns true', ->
        expect(controller.isChromeAppInstalled()).to.be.true

  describe '#notifyChromeAppInstallation', ->
    beforeEach ->
      sinon.stub controller, 'reload'
      controller.notifyChromeAppInstallation()

    it 'makes a PUT request to /user/chrome_app_installed', ->
      lastRequest = server.requests[0]
      expect(lastRequest.method).to.eq 'PUT'
      expect(lastRequest.url).to.eq '/user/chrome_app_installed'
      expect(controller.reload).not.to.have.been.called
      lastRequest.respond 204, {}, ''
      expect(controller.reload).to.have.been.called

  context 'when content.chrome_app changes', ->
    beforeEach ->
      sinon.stub controller, 'notifyChromeAppInstallation'

    context 'when content.chrome_app is null', ->
      context 'if chrome app is installed', ->
        beforeEach ->
          sinon.stub(controller, 'isChromeAppInstalled').returns true
          Em.run -> controller.set 'content', { chrome_app: null }

        it 'calls #notifyChromeAppInstallation', ->
          expect(controller.notifyChromeAppInstallation).to.have.been.called

      context 'if chrome app is not installed', ->
        beforeEach ->
          sinon.stub(controller, 'isChromeAppInstalled').returns false
          Em.run -> controller.set 'content', { chrome_app: null }

        it 'does not call #notifyChromeAppInstallation', ->
          expect(controller.notifyChromeAppInstallation).not.to.have.been.called

    context 'when content.chrome_app is not null', ->
      beforeEach ->
        Em.run -> controller.set 'content', { chrome_app: '2013-01-01' }

      it 'does not call #notifyChromeAppInstallation', ->
        expect(controller.notifyChromeAppInstallation).not.to.have.been.called
