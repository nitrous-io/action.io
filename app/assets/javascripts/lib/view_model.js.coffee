class AIO.ViewModel extends kb.ViewModel
  constructor: ->
    super
    if @errors
      @errorMessages = ko.computed =>
        if @errors()
          errorMessages = {}
          for key, value of @errors()
            errorMessages[key] = value && value[0]
          errorMessages
        else
          {}

class AIO.ReadOnlyViewModel extends AIO.ViewModel
  constructor: (model, options={}) ->
    super(model, _.defaults(options, read_only: true))

