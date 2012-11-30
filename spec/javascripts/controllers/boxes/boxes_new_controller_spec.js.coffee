#= require spec_helper

describe 'AIO.BoxesNewController', ->
  beforeEach -> @controller = AIO.get("router.boxesNewController")

  describe '#newRecord', ->
    it 'creates a new clean box with template id', ->
      Em.run => @controller.newRecord()
      box = @controller.get('content')
      expect(box.get("boxTemplate.name")).to.equal "Ruby on Rails"
