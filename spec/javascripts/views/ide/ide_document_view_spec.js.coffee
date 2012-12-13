describe 'AIO.IdeDocumentView', ->
  cm = document = view = null

  beforeEach ->
    cm = {setOption: ->}
    document = new AIO.Document()
    view = new AIO.IdeDocumentView()
    view.set 'document', document
    view.init()
    view.didInsertElement()
    view.set 'codeMirror', cm

  describe '#activeDidChange', ->
    it 'refreshes the editor', (done) ->
      cm.refresh = sandbox.spy()
      document.set 'active', true
      Em.run.next ->
        expect(cm.refresh).to.have.been.called
        done()

  describe '#documentPathDidChange', ->
    it 'changes mode based on filename', ->
      document.set 'pathname', 'test.rb'
      expect(view.get("mode")).to.equal "text/x-ruby"
