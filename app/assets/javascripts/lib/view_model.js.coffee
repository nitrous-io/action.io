class AIO.ViewModel extends kb.ViewModel

class AIO.ReadOnlyViewModel extends AIO.ViewModel
  constructor: (model, options={}) ->
    super(model, _.defaults(options, read_only: true))

