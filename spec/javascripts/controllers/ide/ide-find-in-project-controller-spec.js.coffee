describe 'App.IdeFindInProjectController', ->
  controller = null

  beforeEach ->
    controller = App.__container__.lookup 'controller:IdeFindInProject'
    controller.reset()

  describe '#guessLocation', ->
    loc = null
    homedir = null

    beforeEach ->
      loc = controller.guessLocation

    it 'returns home directory on empty location', ->
      expect(loc(null)).to.eq homedir
      expect(loc(undefined)).to.eq homedir
      expect(loc('')).to.eq homedir

    it 'returns home directory on file in home directory', ->
      expect(loc('README.md')).to.eq homedir

    it 'returns subdirectory of home directory on nested', ->
      expect(loc('myproject/app/controllers/application_controller.rb')).to.eq 'myproject'
      expect(loc('myproject/.gitignore')).to.eq 'myproject'

    it 'returns subdirectory of workspace directory on nested inside workspace', ->
      expect(loc('workspace/myproject/app/controllers/application_controller.rb')).to.eq 'workspace/myproject'

    it 'returns workspace if given workspace', ->
      expect(loc('workspace')).to.eq 'workspace'
