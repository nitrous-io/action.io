AIO.PublicKey = Em.Resource.extend
  name            : null
  key             : null
  md5_fingerprint : null

  resourceUrl: '/public_keys'
  resourceName: 'public_key'
  resourceProperties: ['name', 'key']

  saving: false

  validate: ->
    errors = null

    key = @get 'key'

    unless key && key.length > 0
      errors ||= {}
      errors.key ||= []
      errors.key.push "can't be blank"

    @set 'errors', errors
    errors

