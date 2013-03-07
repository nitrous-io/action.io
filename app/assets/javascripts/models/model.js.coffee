AIO.Model = AIO.Resource.extend
  save: (cb) ->
    @set 'saving', true
    this.saveResource()
      .fail (e) =>
        if e.status == 422
          @set 'errors', $.parseJSON(e.responseText).errors
      .done =>
        cb()
      .always =>
        @set 'saving', false
