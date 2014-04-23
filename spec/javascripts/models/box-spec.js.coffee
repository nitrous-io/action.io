describe 'App.Box', ->
  model = null

  beforeEach ->
    model = App.Box.create()

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

  describe 'vmem_multiplier', ->
    it 'returns the number of times virtual_memory is of memory', ->
      model.set 'memory', 512
      model.set 'virtual_memory', 512
      expect(model.get 'vmem_multiplier').to.eql 1
      model.set 'memory', 512
      model.set 'virtual_memory', 1024
      expect(model.get 'vmem_multiplier').to.eql 2

    it 'returns a floating point value when virtual_memory is not an integer multiple of memory', ->
      model.set 'memory', 512
      model.set 'virtual_memory', 256
      expect(model.get 'vmem_multiplier').to.eql 0.5
      model.set 'memory', 512
      model.set 'virtual_memory', 768
      expect(model.get 'vmem_multiplier').to.eql 1.5

  describe 'expected_vmem_multiplier', ->
    it 'returns the number of times expected_virtual_memory is of virtual_memory', ->
      model.set 'memory', 512
      model.set 'expected_virtual_memory', 1024
      expect(model.get 'expected_vmem_multiplier').to.eql 2

    it 'returns a floating point value when expected_virtual_memory is not an integer multiple of memory', ->
      model.set 'memory', 512
      model.set 'expected_virtual_memory', 256
      expect(model.get 'expected_vmem_multiplier').to.eql 0.5

  describe 'requiresCPUShareDowngrade', ->
    it 'returns true when expected cpu multiplier is lower than cpu multiplier', ->
      model.set 'cpu_multiplier', 2
      model.set 'expected_cpu_multiplier', 1
      expect(model.get 'requiresCPUShareDowngrade').to.be.true

    it 'returns false when expected cpu multiplier is equal to or higher than cpu multiplier', ->
      model.set 'cpu_multiplier', 1
      model.set 'expected_cpu_multiplier', 1
      expect(model.get 'requiresCPUShareDowngrade').to.be.false
      model.set 'cpu_multiplier', 1
      model.set 'expected_cpu_multiplier', 2
      expect(model.get 'requiresCPUShareDowngrade').to.be.false

  describe 'requiresCPUShareUpgrade', ->
    it 'returns true when expected cpu multiplier is higher than cpu multiplier', ->
      model.set 'cpu_multiplier', 2
      model.set 'expected_cpu_multiplier', 4
      expect(model.get 'requiresCPUShareUpgrade').to.be.true

    it 'returns false when expected cpu multiplier is equal to or lower than cpu multiplier', ->
      model.set 'cpu_multiplier', 1
      model.set 'expected_cpu_multiplier', 1
      expect(model.get 'requiresCPUShareUpgrade').to.be.false
      model.set 'cpu_multiplier', 2
      model.set 'expected_cpu_multiplier', 1
      expect(model.get 'requiresCPUShareUpgrade').to.be.false

  describe 'requiresVirtualMemoryDowngrade', ->
    it 'returns true when expected virtual memory is lower than current virtual memory', ->
      model.set 'virtual_memory', 512
      model.set 'expected_virtual_memory', 256
      expect(model.get 'requiresVirtualMemoryDowngrade').to.be.true

    it 'returns false when expected virtual memory is equal to or higher than current virtual memory', ->
      model.set 'virtual_memory', 512
      model.set 'expected_virtual_memory', 512
      expect(model.get 'requiresVirtualMemoryDowngrade').to.be.false
      model.set 'virtual_memory', 512
      model.set 'expected_virtual_memory', 1024
      expect(model.get 'requiresVirtualMemoryDowngrade').to.be.false

  describe 'requiresVirtualMemoryUpgrade', ->
    it 'returns true when expected virtual memory is higher than current virtual memory', ->
      model.set 'virtual_memory', 512
      model.set 'expected_virtual_memory', 1024
      expect(model.get 'requiresVirtualMemoryUpgrade').to.be.true

    it 'returns false when expected virtual memory is equal to or lower than current virtual memory', ->
      model.set 'virtual_memory', 512
      model.set 'expected_virtual_memory', 512
      expect(model.get 'requiresVirtualMemoryUpgrade').to.be.false
      model.set 'virtual_memory', 512
      model.set 'expected_virtual_memory', 256
      expect(model.get 'requiresVirtualMemoryUpgrade').to.be.false

  describe 'requiresDowngrade', ->
    it 'returns true when either a cpu share or virtual memory downgrade is required', ->
      model.set 'requiresCPUShareDowngrade', true
      expect(model.get 'requiresDowngrade').to.be.true
      model.set 'requiresCPUShareDowngrade', false
      model.set 'requiresVirtualMemoryDowngrade', true
      expect(model.get 'requiresDowngrade').to.be.true
      model.set 'requiresCPUShareDowngrade', true
      expect(model.get 'requiresDowngrade').to.be.true

    it 'returns false when neither a cpu share nor virtual downgrade is required', ->
      model.set 'requiresCPUShareDowngrade', false
      model.set 'requiresVirtualMemoryDowngrade', false
      expect(model.get 'requiresDowngrade').to.be.false

  describe 'requiresUpgrade', ->
    it 'returns true when either a cpu share or virtual memory upgrade is required', ->
      model.set 'requiresCPUShareUpgrade', true
      expect(model.get 'requiresUpgrade').to.be.true
      model.set 'requiresCPUShareUpgrade', false
      model.set 'requiresVirtualMemoryUpgrade', true
      expect(model.get 'requiresUpgrade').to.be.true
      model.set 'requiresCPUShareUpgrade', true
      expect(model.get 'requiresUpgrade').to.be.true

    it 'returns false when neither a cpu share nor virtual upgrade is required', ->
      model.set 'requiresCPUShareUpgrade', false
      model.set 'requiresVirtualMemoryUpgrade', false
      expect(model.get 'requiresDowngrade').to.be.false

  describe 'stateForOrb', ->
    region = App.Region.create()

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

    context 'when the state of the box is cloning_repo', ->
      beforeEach ->
        model.set 'state', 'cloning_repo'

      it 'returns "cloning repository"', ->
        expect(model.get 'stateForDisplay').to.eql 'downloading repository'

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
    beforeEach ->
      model.set 'region_id', 2

    it 'returns the region', ->
      region = model.get 'region'
      expect(region.get 'id').to.equal 2
      expect(region.get 'name').to.equal 'us-west-1'

  describe 'boxTemplate', ->
    boxTemplateId = '8383'

    beforeEach ->
      sinon.stub App.BoxTemplate, 'findById'
      App.BoxTemplate.findById.returns boxTemplateId

    afterEach ->
      App.BoxTemplate.findById.restore()

    it 'returns the box template id', ->
      expect(model.get 'boxTemplate').to.eql(boxTemplateId)

  describe 'sourceSnapshot', ->
    sourceSnapshot = null

    beforeEach ->
      sourceSnapshot = App.Snapshot.create(id: 42)
      App.Snapshot.all().set 'content', Em.A([sourceSnapshot])

    afterEach ->
      App.Snapshot.all().set 'content', Em.A()

    it 'returns the source snapshot', ->
      model.set 'source_snapshot_id', 42
      expect(model.get 'sourceSnapshot').to.eql(sourceSnapshot)

    it 'returns null when box does not have a source snapshot', ->
      model.set 'source_snapshot_id', null
      expect(model.get 'sourceSnapshot').not.to.exist

  describe 'snapshots', ->
    snapshot1 = snapshot2 = snapshot3 = null

    beforeEach ->
      App.Snapshot.all().set 'content', Em.A([
        snapshot1 = Em.Object.create(name: 'match-1', box_id: 23)
        snapshot2 = Em.Object.create(name: 'match-2', box_id: 23)
        snapshot3 = Em.Object.create(name: 'nomatch', box_id: 1)
      ])
      model.set 'id', 23

    afterEach ->
      App.Snapshot.all().set 'content', Em.A()

    it 'returns snapshots for this box', ->
      expect(model.get 'snapshots.content').to.deep.eql([snapshot1, snapshot2])

  describe 'snapshottable', ->
    it 'returns true if box state is stopped', ->
      model.set 'state', 'stopped'
      expect(model.get 'snapshottable').to.be.true

    it 'returns false if box state is not stopped', ->
      model.set 'state', 'running'
      expect(model.get 'snapshottable').to.be.false

  describe 'webTerminalPath', ->
    originalUrl = null

    beforeEach ->
      originalUrl = App.Box.url
      App.Box.url = '/some/url'
      model.set 'id', 123

    afterEach ->
      App.Box.url = originalUrl
      model.set 'id', null

    it 'returns the web terminal path', ->
      expect(model.get 'webTerminalPath').to.eql("/some/url/123/terminal")

  states = ['stopped', 'running', 'terminated', 'provisioning', 'snapshotting']
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

  describe '#hasBaseCPUShare', ->
    it 'returns true if the CPU multipler of the box is 1', ->
      model.set 'cpu_multiplier', 1
      expect(model.get('hasBaseCPUShare')).to.be.true

    it 'returns true if the CPU multipler of the box is more than 1', ->
      model.set 'cpu_multiplier', 2
      expect(model.get('hasBaseCPUShare')).to.be.false

  describe '#ownBox', ->
    it 'checks if currentUser owns the box', ->
      model.set 'owner_id', 2
      user = {id: 1}
      App.set('currentUser', user)
      expect(model.get("ownBox")).to.be.false

      user = {id: 2}
      App.set('currentUser', user)
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
        window.server.respondWith "PUT", "/boxes/123/start.json",
                             [ 200, { "Content-Type": "application/json" },
                             '{ "box": { "state": "starting" } }' ]
        model.makeBoxControlRequest 'start'
        window.server.respond()

      it 'loading flag is set to false', ->
        expect(model.get 'loading').to.be.false

      it 'deserializes the JSON response', ->
        expect(model.get 'state').to.equal 'starting'

    context 'when response is a 422 error', ->
      beforeEach ->
        window.server.respondWith "PUT", "/boxes/123/start.json",
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
        window.server.respondWith "DELETE", "/boxes/123.json",
                                  [ 200, { "Content-Type": "application/json" },
                                  '{ "box": { "name": "sample-box" } }' ]
        model.terminate()
        window.server.respond()

      it 'loading flag is set to false', ->
        expect(model.get 'loading').to.be.false

    context 'when response is a 422 error', ->
      beforeEach ->
        window.server.respondWith "DELETE", "/boxes/123.json",
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
        window.server.respondWith "DELETE", "/boxes/123/collaborators/testUser.json",
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
        window.server.respondWith "DELETE", "/boxes/123/collaborators/testUser.json",
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

  describe '.minBoxN2O', ->
    beforeEach ->
      App.set 'config.minMemoryMB', 256
      App.set 'config.n2o128mbMemory', 20
      App.set 'config.minStorageMB', 1000
      App.set 'config.n2o250mbStorage', 10

    afterEach ->
      App.set 'config.minMemoryMB', null
      App.set 'config.n2o128mbMemory', null
      App.set 'config.minStorageMB', null
      App.set 'config.n2o250mbStorage', null

    it 'returns the minimum N2O cost of creating 1 box', ->
      expect(App.Box.minBoxN2O()).to.eql 20 * 256/128 + 10 * 1000/250

