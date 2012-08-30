describe 'aio.helpers.AppHelper', ->
  describe '#showErrorsOnForm', ->
    before ->
      loadFixtures('form_without_errors.html')
      aio.helpers.AppHelper.showErrorsOnForm $('#jasmine-fixtures form')
      , JSON.stringify
          errors:
            name: ["can't be blank", "is too short"]
            box_template_id: ["some kind of error"]

    it 'highlights errors by adding "error" class to the control-group', ->
      expect($('[data-spec="name-control-group"]').hasClass('error')).toBe true
      expect($('[data-spec="region-control-group"]').hasClass('error')).toBe false
      expect($('[data-spec="box_template_id-control-group"]').hasClass('error')).toBe true

    it 'adds an inline help span with the error message', ->
      $nameHelp = $('[data-spec="name-control-group"] .controls span.help-inline')
      expect($nameHelp.length).toEqual 1
      expect($nameHelp.text()).toEqual "can't be blank; is too short"
      $boxTemplateIdHelp = $('[data-spec="box_template_id-control-group"] .controls span.help-inline')
      expect($boxTemplateIdHelp.length).toEqual 1
      expect($boxTemplateIdHelp.text()).toEqual 'some kind of error'

  describe '#handleErrorResponse', ->
    mockObj = $()

    before ->
      spyOn(window, 'alert')

    context 'when the error code is 422 and the responseText contains ""errors":{"', ->
      it 'calls showErrorsOnForm', ->
        responseText = '{"errors":{"name":["can\'t be blank"}}'
        response =
          status: 422
          statusText: 'Unprocessable Entity'
          responseText: responseText
        spyOn(aio.helpers.AppHelper, 'showErrorsOnForm')
        aio.helpers.AppHelper.handleErrorResponse(response, mockObj)
        expect(aio.helpers.AppHelper.showErrorsOnForm).toHaveBeenCalledWith(mockObj, responseText)

    context 'when the error code is something other than 422', ->
      it 'shows alert dialog', ->
        response =
          status: 500
          statusText: 'Internal Server Error'
          responseText: 'Something went wrong.'
        aio.helpers.AppHelper.handleErrorResponse(response, mockObj)
        expect(window.alert).toHaveBeenCalledWith("500 Internal Server Error\nSomething went wrong.")

