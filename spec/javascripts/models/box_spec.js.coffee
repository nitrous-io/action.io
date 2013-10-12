describe 'AIO.Box', ->
  model = null

  beforeEach ->
    model = AIO.Box.create()

  describe 'validations', ->
    context 'name', ->
      it 'validates name to not exist ', ->
        model.set 'name', null
        model.validate()
        expect(model.get 'errors.name').to.exist

      it 'validates name to exist ', ->
        model.set 'name', 'foo'
        model.validate()
        expect(model.get 'errors.name').not.to.exist

    context 'region_id', ->
      it 'validates region_id not to exist', ->
        model.set 'region_id', null
        model.validate()
        expect(model.get 'errors.region_id').to.exist

      it 'validates region_id to exist', ->
        model.set 'region_id', '123'
        model.validate()
        expect(model.get 'errors.region_id').not.to.exist

    context 'box_template_id', ->
      it 'validates box_template_id not to exist', ->
        model.set 'box_template_id', null
        model.validate()
        expect(model.get 'errors.box_template_id').to.exist

      it 'validates box_template_id to exist', ->
        model.set 'box_template_id', '5678'
        model.validate()
        expect(model.get 'errors.box_template_id').not.to.exist

  describe 'stateForOrb', ->
    region = AIO.Region.create()

    beforeEach ->
      model.set 'state', 'running'
      model.set 'region', region

    it 'returns the state when the box is not under maintenance', ->
      region.set 'enabled', true
      expect(model.get 'stateForOrb').to.eql 'running'

    it 'returns under_maintenance when the box is under maintenance', ->
      region.set 'enabled', false
      expect(model.get 'stateForOrb').to.eql 'under_maintenance'

  describe 'stateForDisplay', ->
    context 'when the state of the box is failed', ->
      beforeEach ->
        model.set 'state', 'failed'

      it 'returns "provisioning failed"', ->
        expect(model.get 'stateForDisplay').to.eql 'provisioning failed'

    context 'when the state of the box is running', ->
      beforeEach ->
        model.set 'state', 'running'

      it 'returns running', ->
        expect(model.get 'stateForDisplay').to.eql 'running'

  describe 'sshURI', ->
    host = 'example.com'
    port = '4090'

    it 'returns the sshURI', ->
      model.set 'host', host
      model.set 'port', port
      expect(model.get 'sshURI').to.eql("ssh://action@#{host}:#{port}")

    it 'returns null when there is no port', ->
      model.set 'host', host
      model.set 'port', null
      expect(model.get 'sshURI').not.to.exist

    it 'returns null when there is no host', ->
      model.set 'host', null
      model.set 'port', port
      expect(model.get 'sshURI').not.to.exist

    it 'returns null when there is no host and no port', ->
      model.set 'host', null
      model.set 'port', null
      expect(model.get 'sshURI').not.to.exist

  describe 'boxHost', ->
    containerName = 'nice-name'
    host = 'limbo.com'

    it 'returns the box host', ->
      model.set 'container_name', containerName
      model.set 'host', host
      expect(model.get 'boxHost').to.eql("#{containerName}.#{host}")

    it 'returns null when there is no name', ->
      model.set 'container_name', null
      model.set 'host', host
      expect(model.get 'boxHost').not.to.exist

    it 'returns null when there is no host', ->
      model.set 'container_name', containerName
      model.set 'host', null
      expect(model.get 'boxHost').not.to.exist

    it 'returns null when there is no host and no name', ->
      model.set 'container_name', null
      model.set 'host', null
      expect(model.get 'boxHost').not.to.exist

  describe 'previewDomain', ->
    containerName = 'nice-name'
    previewHost = 'limbo.com'
    label = 'reg1'
    region = AIO.Region.create label: label

    beforeEach ->
      sinon.stub AIO, 'get'
      AIO.get.withArgs('previewHost').returns previewHost

    afterEach ->
      AIO.get.restore()

    it 'returns the preview domain', ->
      model.set 'container_name', containerName
      model.set 'region', region
      expect(model.get 'previewDomain').to.eql("#{containerName}.#{label}.#{previewHost}")

    it 'returns null when there is no name', ->
      model.set 'container_name', null
      model.set 'region', region
      expect(model.get 'previewDomain').not.to.exist

    it 'returns null when there is no region', ->
      model.set 'container_name', containerName
      model.set 'region', null
      expect(model.get 'previewDomain').not.to.exist

    it 'returns null when there is no region label', ->
      model.set 'container_name', containerName
      region.set 'label', null
      model.set 'region', region
      expect(model.get 'previewDomain').not.to.exist

    it 'returns null when there is no region and no name', ->
      model.set 'container_name', null
      model.set 'region', null
      expect(model.get 'previewDomain').not.to.exist

  describe 'region', ->
    region = 'middle earth'

    beforeEach ->
      sinon.stub AIO.get('router.regionsController'), 'findById'
      AIO.get('router.regionsController').findById.returns region

    afterEach ->
      AIO.get('router.regionsController').findById.restore()

    it 'returns the region', ->
      expect(model.get 'region').to.eql(region)

  describe 'boxTemplate', ->
    boxTemplateId = '8383'

    beforeEach ->
      sinon.stub AIO.get('router.boxTemplatesController'), 'findById'
      AIO.get('router.boxTemplatesController').findById.returns boxTemplateId

    afterEach ->
      AIO.get('router.boxTemplatesController').findById.restore()

    it 'returns the box template id', ->
      expect(model.get 'boxTemplate').to.eql(boxTemplateId)

  describe 'webTerminalPath', ->
    resourceUrl = '/some/url'
    resourceId = '123'

    beforeEach ->
      model.set 'resourceUrl', resourceUrl
      model.set 'id', resourceId

    afterEach ->
      model.set 'resourceUrl', null
      model.set 'id', null

    it 'returns the web terminal path', ->
      expect(model.get 'webTerminalPath').to.eql("#{resourceUrl}/#{resourceId}/terminal")

  states = ['stopped', 'running', 'terminated', 'provisioning']
  _.each states, (state, index) ->
    describe state, ->
      it "returns true if the state equals #{state}", ->
        model.set 'state', state
        expect(model.get state).to.be.true

      it "returns false if the state is not #{state}", ->
        model.set 'state', 'foo'
        expect(model.get state).to.be.false

  describe 'working', ->
    it 'returns true if the state is not amongst the working states', ->
      model.set 'state', 'dreaming'
      expect(model.get 'working').to.be.true

    it 'returns false if the state is amongst the working states', ->
      model.set 'state', states[0]
      expect(model.get 'working').to.be.false

  describe '#ownBox', ->
    it 'checks if currentUser owns the box', ->
      model.set 'owner_id', 2
      user = {id: 1}
      AIO.set('currentUser', user)
      expect(model.get("ownBox")).to.be.false

      user = {id: 2}
      AIO.set('currentUser', user)
      expect(model.get("ownBox")).to.be.true

  describe '#makeBoxControlRequest', ->
    beforeEach ->
      model.set 'id', 123

    afterEach ->
      model.set 'id', null

    it 'loading flag is set to true', ->
      model.makeBoxControlRequest 'start'
      expect(model.get 'loading').to.be.true

    context 'when response is successful', ->
      beforeEach ->
        window.server.respondWith "PUT", "/boxes/123/start",
                             [ 200, { "Content-Type": "application/json" },
                             '{ "box": { "state": "starting" } }' ]
        model.makeBoxControlRequest 'start'
        window.server.respond()

      it 'loading flag is set to false', ->
        expect(model.get 'loading').to.be.false

      it 'deserializes the JSON response', ->
        expect(model.get 'state').to.eql "starting"

    context 'when response is a 422 error', ->
      beforeEach ->
        window.server.respondWith "PUT", "/boxes/123/start",
                             [ 422, { "Content-Type": "application/json" },
                             '{ "errors": { "base": ["Some error occurred."] } }' ]
        model.makeBoxControlRequest 'start'
        window.server.respond()

      it 'sets the error', ->
        expect(model.get 'errors').to.eql { base: [ "Some error occurred." ] }

      it 'loading flag is set to false', ->
        expect(model.get 'loading').to.be.false

  describe '#terminate', ->
    beforeEach ->
      model.set 'id', 123

    afterEach ->
      model.set 'id', null

    it 'loading flag is set to true', ->
      model.makeBoxControlRequest 'start'
      expect(model.get 'loading').to.be.true

    context 'when response is successful', ->
      beforeEach ->
        window.server.respondWith "DELETE", "/boxes/123",
                                  [ 200, { "Content-Type": "application/json" },
                                  '{ "box": { "name": "sample-box" } }' ]
        model.terminate()
        window.server.respond()

      it 'loading flag is set to false', ->
        expect(model.get 'loading').to.be.false

    context 'when response is a 422 error', ->
      beforeEach ->
        window.server.respondWith "DELETE", "/boxes/123",
                                  [ 422, { "Content-Type": "application/json" },
                                  '{ "errors": { "base": ["Some error occurred."] } }' ]
        model.terminate()
        window.server.respond()

      it 'sets a base error', ->
        expect(model.get 'errors').to.eql { base: [ "Some error occurred." ] }

      it 'loading flag is set to false', ->
        expect(model.get 'loading').to.be.false

  describe '#removeCollaborator', ->
    cbSpy = null

    beforeEach ->
      model.set 'id', 123
      cbSpy = sinon.spy()

    afterEach ->
      model.set 'id', null

    it 'loading flag is set to true', ->
      model.removeCollaborator 'testUser', cbSpy
      expect(model.get 'loading').to.be.true

    context 'when response is successful', ->
      beforeEach ->
        window.server.respondWith "DELETE", "/boxes/123/collaborators/testUser",
                                  [ 200, { "Content-Type": "application/json" },
                                  '' ]
        model.removeCollaborator 'testUser', cbSpy
        window.server.respond()

      it 'loading flag is set to false', ->
        expect(model.get 'loading').to.be.false

      it 'invokes the callback with true', ->
        expect(cbSpy).to.have.been.calledWith true

    context 'when response is a 422 error', ->
      beforeEach ->
        window.server.respondWith "DELETE", "/boxes/123/collaborators/testUser",
                                  [ 422, { "Content-Type": "application/json" },
                                  '{ "errors": { "base": ["Some error occurred."] } }' ]
        model.removeCollaborator 'testUser'
        window.server.respond()

      it 'sets a base error', ->
        expect(model.get 'errors').to.eql { base: [ "Some error occurred." ] }

      it 'loading flag is set to false', ->
        expect(model.get 'loading').to.be.false

  describe '#underMaintenance', ->
    beforeEach ->
      model.set 'region', Em.Object.create(enabled: true)
      model.set 'state', 'running'

    it 'returns true when the region is disabled', ->
      model.set('region.enabled', false)
      expect(model.get('underMaintenance')).to.be.true

    it 'returns true when the box is under maintenance', ->
      model.set('state', 'migrating')
      expect(model.get('underMaintenance')).to.be.true

    it 'returns false by default', ->
      expect(model.get('underMaintenance')).to.be.false
