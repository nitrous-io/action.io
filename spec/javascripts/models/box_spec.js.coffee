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

    name = 'nice-name'
    host = 'limbo.com'

    it 'returns the box host', ->
      model.set 'name', name
      model.set 'host', host
      expect(model.get 'boxHost').to.eql("#{name}.#{host}")

    it 'returns null when there is no name', ->
      model.set 'name', null
      model.set 'host', host
      expect(model.get 'boxHost').not.to.exist

    it 'returns null when there is no host', ->
      model.set 'name', name
      model.set 'host', null
      expect(model.get 'boxHost').not.to.exist

    it 'returns null when there is no host and no name', ->
      model.set 'name', null
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
