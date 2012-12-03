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
      sinon.stub AIO.get('router.regionsController'), 'findById'
      AIO.get('router.regionsController').findById.returns region

    afterEach ->
      AIO.get('router.regionsController').findById.restore()

    context 'when the region associated with the box is enabled', ->
      beforeEach ->
        region.set 'enabled', true

      it 'returns running', ->
        expect(model.get 'stateForOrb').to.eql 'running'

    context 'when the region associated with the box is disabled', ->
      beforeEach ->
        region.set 'enabled', false

      it 'returns under_maintenance', ->
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

  describe '#owner', ->
    it 'returns owner of the box', ->
      user = sinon.stub()
      AIO.set("router.applicationController.currentUser", user)
      expect(model.get("owner")).to.eql user

<<<<<<< HEAD
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
                             [ 200, { "Content-Type": "apllication/json" },
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
                             [ 422, { "Content-Type": "apllication/json" },
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
                                  [ 200, { "Content-Type": "apllication/json" },
                                  '{ "box": { "name": "sample-box" } }' ]
        model.terminate()
        window.server.respond()

      it 'loading flag is set to false', ->
        expect(model.get 'loading').to.be.false

    context 'when response is a 422 error', ->
      beforeEach ->
        window.server.respondWith "DELETE", "/boxes/123",
                                  [ 422, { "Content-Type": "apllication/json" },
                                  '{ "errors": { "base": ["Some error occurred."] } }' ]
        model.terminate()
        window.server.respond()

      it 'sets a base error', ->
        expect(model.get 'errors').to.eql { base: [ "Some error occurred." ] }

      it 'loading flag is set to false', ->
        expect(model.get 'loading').to.be.false

  describe '#adminsUrl', ->
    it 'returns url to the list admins section', ->
      model.set 'id', 123
      expect(model.get('adminsUrl')).to.eq("/boxes/123/admins")
