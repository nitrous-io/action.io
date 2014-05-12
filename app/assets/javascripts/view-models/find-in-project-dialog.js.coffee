App.FindInProjectDialog = Em.Object.extend
  errors: null
  term: null
  location: null

  valid: ->
    errors = {}
    if (@get('term') || '').trim() == ''
      errors.term = 'is required'

    @set 'errors', errors

    return _.isEmpty(errors)
