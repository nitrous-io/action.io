describe 'AIO.Repository', ->
  model = null

  beforeEach ->
    model = AIO.Repository.create()

  describe 'box', ->
    box = Em.Object.create(id: 42, name: 'box-1')

    beforeEach ->
      sinon.stub AIO.get('router.boxesController'), 'findById'
      AIO.get('router.boxesController').findById.withArgs(42).returns box

    afterEach ->
      AIO.get('router.boxesController').findById.restore()

    it 'returns the box it belongs to', ->
      model.set 'box_id', 42
      expect(model.get 'box').to.eql(box)

    it 'returns null when repository does not belong to a box', ->
      model.set 'box_id', null
      expect(model.get 'box').not.to.exist

  describe 'displayName', ->
    context 'when clone_url is a valid SCM URI', ->
      beforeEach ->
        model.set 'clone_url', 'https://github.com/nitrous-io/autoparts.git'

      it 'returns the repository name in "author/name" format', ->
        expect(model.get 'displayName').to.eql('nitrous-io/autoparts')

    context 'when clone_url is not a valid SCM URI', ->
      beforeEach ->
        model.set 'clone_url', 'https://github.com'

      it 'returns nil', ->
        expect(model.get 'displayName').to.be.nil

  describe 'shortName', ->
    context 'when clone_url is a valid SCM URI', ->
      beforeEach ->
        model.set 'clone_url', 'https://github.com/nitrous-io/autoparts.git'

      it 'returns the repository name', ->
        expect(model.get 'shortName').to.eql('autoparts')

    context 'when clone_url is not a valid SCM URI', ->
      beforeEach ->
        model.set 'clone_url', 'https://github.com'

      it 'returns nil', ->
        expect(model.get 'shortName').to.be.nil

  describe 'author', ->
    context 'when clone_url is a valid SCM URI', ->
      beforeEach ->
        model.set 'clone_url', 'https://github.com/nitrous-io/autoparts.git'

      it 'returns the author name', ->
        expect(model.get 'author').to.eql('nitrous-io')

    context 'when clone_url is not a valid SCM URI', ->
      beforeEach ->
        model.set 'clone_url', 'https://github.com'

      it 'returns nil', ->
        expect(model.get 'author').to.be.nil

  describe 'tokenizedCloneURL', ->
    context 'when clone_url can be tokenized', ->
      beforeEach ->
        model.set 'clone_url', 'https://github.com/nitrous-io/autoparts.git'

      it 'returns an object with author and name', ->
        expect(model.get 'tokenizedCloneURL.author').to.eql('nitrous-io')
        expect(model.get 'tokenizedCloneURL.name').to.eql('autoparts')

    context 'when URL cannot be tokenized', ->
      beforeEach ->
        model.set 'clone_url', 'https://github.com'

      it 'returns nil', ->
        expect(model.get 'tokenizedCloneURL').to.be.nil

  describe 'isGithub', ->
    context 'when clone_url can be tokenized and is from Github', ->
      beforeEach ->
        model.set 'clone_url', 'https://github.com/nitrous-io/autoparts.git'

      it 'returns true', ->
        expect(model.get 'isGithub').to.eql(true)

    context 'when clone_url is not from Github', ->
      beforeEach ->
        model.set 'clone_url', 'https://bitbucket.com/nitrous-io/autoparts.git'

      it 'returns true', ->
        expect(model.get 'isGithub').to.eql(false)

    context 'when clone_url cannot be tokenized but is from Github', ->
      beforeEach ->
        model.set 'clone_url', 'https://github.com'

      it 'returns false', ->
        expect(model.get 'isGithub').to.eql(false)
