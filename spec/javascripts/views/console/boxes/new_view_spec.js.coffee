describe 'aio.views.console.boxes.NewView', ->
  [view, boxTemplate1, boxTemplate2] = []

  before ->
    boxTemplate1 = new aio.models.BoxTemplate(id: 1, name: 'us-east-1')
    boxTemplate2 = new aio.models.BoxTemplate(id: 2, name: 'ap-southeast-1')
    aio.app.boxes = new aio.collections.Boxes
    aio.app.boxTemplates = new aio.collections.BoxTemplates
    aio.app.boxTemplates.reset([boxTemplate1, boxTemplate2])
    view = new aio.views.console.boxes.NewView(collection: aio.app.boxes)
    $('#jasmine-fixtures').append(view.render().$el)

  describe 'filling up the form', ->
    before ->
      $('#box_name').val('fragrant-wind-69').change()
      $('#box_region').val('ap-southeast-1').change()
      $('#box_box_template_id').val('2').change()

    it 'has its model bound to the changes in the form', ->
      expect(view.model.get('name')).toEqual 'fragrant-wind-69'
      expect(view.model.get('region')).toEqual 'ap-southeast-1'
      expect(view.model.get('box_template_id')).toEqual '2'

    context 'upon clicking create box button', ->
      request = null

      before ->
        jasmine.Ajax.useMock()
        $('#console-boxes-new .submit').click()
        request = mostRecentAjaxRequest()

      it 'sends a POST request to /boxes', ->
        expect(request.method).toEqual 'POST'
        expect(request.url).toEqual '/boxes'
        params = JSON.parse(request.params)
        expect(params.name).toEqual 'fragrant-wind-69'
        expect(params.region).toEqual 'ap-southeast-1'
        expect(params.box_template_id).toEqual '2'

      context 'upon receiving a successful response by the server', ->
        before ->
          spyOn(window, 'navigateTo')
          request.response
            status: 201
            responseText: JSON.stringify(_.extend(view.model.toJSON(), id: 123))

        it 'adds the newly created box to the boxes collection', ->
          expect(aio.app.boxes.models).toContain view.model

        it 'navigates to #boxes/:id', ->
          expect(window.navigateTo).toHaveBeenCalledWith('#boxes/123')

