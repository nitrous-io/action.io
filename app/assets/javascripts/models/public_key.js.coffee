AIO.PublicKey = AIO.Model.extend
  name            : DS.attr('string')
  key             : DS.attr('string')
  md5_fingerprint : DS.attr('string')
  user            : DS.belongsTo('AIO.User')

  validations:
    key: (v) -> "can't be blank" unless v && v.length > 0
