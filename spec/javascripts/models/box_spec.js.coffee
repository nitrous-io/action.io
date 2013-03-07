describe 'AIO.Box', ->
  model = null

  beforeEach ->
    model = AIO.Box.createRecord()

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

    context 'region', ->
      it 'validates region not to exist', ->
        model.set 'region', null
        model.validate()
        expect(model.get 'errors.region').to.exist

      it 'validates region_id to exist', ->
        model.set 'region', Em.Object.create(id: 1)
        model.validate()
        expect(model.get 'errors.region').not.to.exist

    context 'boxTemplate', ->
      it 'validates boxTemplate not to exist', ->
        model.set 'boxTemplate', null
        model.validate()
        expect(model.get 'errors.boxTemplate').to.exist

      it 'validates boxTemplate to exist', ->
        model.set 'boxTemplate', Em.Object.create(id: 1)
        model.validate()
        expect(model.get 'errors.boxTemplate').not.to.exist

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
      model.set 'containerName', containerName
      model.set 'host', host
      expect(model.get 'boxHost').to.eql("#{containerName}.#{host}")

    it 'returns null when there is no name', ->
      model.set 'containerName', null
      model.set 'host', host
      expect(model.get 'boxHost').not.to.exist

    it 'returns null when there is no host', ->
      model.set 'containerName', containerName
      model.set 'host', null
      expect(model.get 'boxHost').not.to.exist

    it 'returns null when there is no host and no name', ->
      model.set 'containerName', null
      model.set 'host', null
      expect(model.get 'boxHost').not.to.exist

  describe 'webTerminalPath', ->
    it 'returns the web terminal path', ->
      model.set 'id', 123
      expect(model.get 'webTerminalPath').to.eql("/boxes/123/terminal")

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
