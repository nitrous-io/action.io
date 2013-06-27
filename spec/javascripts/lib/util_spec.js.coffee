describe 'AIO.util', ->
  describe 'humanizedTimeProperty', ->
    ExampleModel = Em.Object.extend
      created_at: null
      humanizedCreatedAt: AIO.util.humanizedTimeProperty('created_at')

    model = null

    dateStringWithOffsetInPast = (offsetInSeconds) ->
      new Date(new Date() - (offsetInSeconds * 1000)).toISOString()

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

    context '60 days ago', ->
      it 'should return "2 months ago"', ->
        model.set 'created_at', dateStringWithOffsetInPast(60 * 60 * 24 * 60)
        expect(model.get 'humanizedCreatedAt').to.eql '2 months ago'

    context '600 days ago', ->
      it 'should return "last year"', ->
        model.set 'created_at', dateStringWithOffsetInPast(60 * 60 * 24 * 600)
        expect(model.get 'humanizedCreatedAt').to.eql 'last year'

    context '800 days ago', ->
      it 'should return "2 years ago"', ->
        model.set 'created_at', dateStringWithOffsetInPast(60 * 60 * 24 * 800)
        expect(model.get 'humanizedCreatedAt').to.eql '2 years ago'

