AIO.PublicKey = AIO.Resource.extend
  name            : null
  key             : null
  md5_fingerprint : null
  user_id         : null

  resourceUrl: '/public_keys'
  resourceName: 'public_key'
  resourceProperties: ['name', 'key']

  validations:
    key: (v) -> "can't be blank" unless v && v.length > 0

