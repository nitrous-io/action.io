aio.helpers.AppHelper = self =
  showErrorsOnForm: ($form, errorJSON) ->
    errorHash = JSON.parse(errorJSON).errors
    for own field, errors of errorHash
      $input = $form.find("[name='#{field}']:input")
      $input.closest('.control-group').addClass('error')
      $controls = $input.closest('.controls')
      $helpSpan = $controls.find('span.help-inline')
      if $helpSpan.length == 0
        $helpSpan = $("<span class='help-inline'>").appendTo($controls)
      $helpSpan.text(errors.join('; '))

  handleErrorResponse: (response, $form) ->
    responseText = response.responseText
    if response.status == 422 && responseText.match(/"errors":{/)
      self.showErrorsOnForm($form, responseText)
    else
      window.alert("#{response.status} #{response.statusText}\n#{responseText}")

