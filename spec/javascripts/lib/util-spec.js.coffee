describe 'App.util', ->
  describe 'humanizedTimeProperty', ->
    ExampleModel = Em.Object.extend
      created_at: null
      humanizedCreatedAt: App.util.humanizedTimeProperty('created_at')

    model = null

    dateStringWithOffsetInPast = (offsetInSeconds) ->
      new Date(+new Date() - (offsetInSeconds * 1000)).toISOString()

    beforeEach ->
      model = ExampleModel.create()

    context 'few seconds ago', ->
      it 'should return "just now"', ->
        model.set 'created_at', dateStringWithOffsetInPast(5)
        expect(model.get 'humanizedCreatedAt').to.eql 'just now'

    context '1.5 minutes ago', ->
      it 'should return "a minute ago"', ->
        model.set 'created_at', dateStringWithOffsetInPast(90)
        expect(model.get 'humanizedCreatedAt').to.eql 'a minute ago'

    context '5 minutes ago', ->
      it 'should return "5 minutes ago"', ->
        model.set 'created_at', dateStringWithOffsetInPast(5 * 60)
        expect(model.get 'humanizedCreatedAt').to.eql '5 minutes ago'

    context '1.5 hours ago', ->
      it 'should return "an hour ago"', ->
        model.set 'created_at', dateStringWithOffsetInPast(60 * 60 * 1.5)
        expect(model.get 'humanizedCreatedAt').to.eql 'an hour ago'

    context '12 hours ago', ->
      it 'should return "12 minutes ago"', ->
        model.set 'created_at', dateStringWithOffsetInPast(60 * 60 * 12)
        expect(model.get 'humanizedCreatedAt').to.eql '12 hours ago'

    context '26 hours ago', ->
      it 'should return "12 minutes ago"', ->
        model.set 'created_at', dateStringWithOffsetInPast(60 * 60 * 26)
        expect(model.get 'humanizedCreatedAt').to.eql 'yesterday'

    context '5 days ago', ->
      it 'should return "5 days ago"', ->
        model.set 'created_at', dateStringWithOffsetInPast(60 * 60 * 24 * 5)
        expect(model.get 'humanizedCreatedAt').to.eql '5 days ago'

    context '20 days ago', ->
      it 'should return "3 weeks ago"', ->
        model.set 'created_at', dateStringWithOffsetInPast(60 * 60 * 24 * 20)
        expect(model.get 'humanizedCreatedAt').to.eql '3 weeks ago'

    context '62 days ago', ->
      it 'should return "2 months ago"', ->
        model.set 'created_at', dateStringWithOffsetInPast(60 * 60 * 24 * 62)
        expect(model.get 'humanizedCreatedAt').to.eql '2 months ago'

    context '600 days ago', ->
      it 'should return "last year"', ->
        model.set 'created_at', dateStringWithOffsetInPast(60 * 60 * 24 * 600)
        expect(model.get 'humanizedCreatedAt').to.eql 'last year'

    context '800 days ago', ->
      it 'should return "2 years ago"', ->
        model.set 'created_at', dateStringWithOffsetInPast(60 * 60 * 24 * 800)
        expect(model.get 'humanizedCreatedAt').to.eql '2 years ago'

    context 'when passed a date object', ->
      it 'should still be able to handle it', ->
        model.set 'created_at', new Date(+new Date() - 5 * 1000)
        expect(model.get 'humanizedCreatedAt').to.eql 'just now'

  describe 'randomElement', ->
    it 'should return a random element', ->
      array = [0, 1, 2, 3]

      sinon.stub(Math, 'random').returns(0)
      expect(App.util.randomElement(array)).to.eql 0
      Math.random.restore()

      sinon.stub(Math, 'random').returns(0.25)
      expect(App.util.randomElement(array)).to.eql 1
      Math.random.restore()

      sinon.stub(Math, 'random').returns(0.5)
      expect(App.util.randomElement(array)).to.eql 2
      Math.random.restore()

      sinon.stub(Math, 'random').returns(0.99)
      expect(App.util.randomElement(array)).to.eql 3
      Math.random.restore()

  describe 'autolink', ->
    it 'should link to urls', ->
      textWithHTTPUrl = 'Wow! check this awesome app - http://nitrous.io'
      expect(App.util.autolink(textWithHTTPUrl).toString()).to.eql "Wow! check this awesome app - <a href='http://nitrous.io' target='_blank'>http://nitrous.io</a>"

      textWithHTTPSUrl = 'Can you check this file? - https://gist.github.com/laktek/10001'
      expect(App.util.autolink(textWithHTTPSUrl).toString()).to.eql "Can you check this file? - <a href='https://gist.github.com/laktek/10001' target='_blank'>https://gist.github.com/laktek/10001</a>"

    it 'should escape user added HTML entities', ->
      textWithHTMLAndUrl = '<script>alert("YOLO")</script> http://nitrous.io'
      expect(App.util.autolink(textWithHTMLAndUrl).toString()).to.eql "&lt;script&gt;alert(&quot;YOLO&quot;)&lt;/script&gt; <a href='http://nitrous.io' target='_blank'>http://nitrous.io</a>"
