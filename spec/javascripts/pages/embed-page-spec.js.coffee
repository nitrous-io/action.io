#= require pages/embed-page

describe 'App.EmbedPage', ->
  embedPage = null

  beforeEach ->
    sinon.stub Handlebars, 'compile'
    embedPage = new App.EmbedPage()

  afterEach ->
    Handlebars.compile.restore()

  describe '#validateRepoName', ->
    it 'should accept repo names with dots', ->
      expect(embedPage.validateRepoName 'emberjs/ember.js').not.to.be.null

    it 'should not accept invalid repo names', ->
      expect(embedPage.validateRepoName 'ember.js/ember.js').to.be.null
