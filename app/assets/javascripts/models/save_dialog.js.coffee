AIO.SaveDialog = Em.Object.extend AIO.Validatable,
  path: ''
  saving: false
  document: null
  visible: false

  validations:
    path: (v) ->
      v = $.trim(v) if v
      if !v || v.substr(-1) == '/'
        'is not a valid path'
      else
        for pathComponent in v.split '/'
          unless pathComponent.match /^[^\/\\:\*\?"<>\|]*[^\/\\:\*\?"<>\|\.]+[^\/\\:\*\?"<>\|]*$/
            return 'is not a valid path'

