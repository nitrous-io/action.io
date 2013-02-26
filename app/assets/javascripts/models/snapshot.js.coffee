AIO.Snapshot = AIO.Model.extend
  name             : DS.attr('string')
  description      : DS.attr('string')
  state            : DS.attr('string')
  public           : DS.attr('boolean')
  box              : DS.belongsTo('AIO.Box')
  owner            : DS.belongsTo('AIO.User')
  expanded         : false

  validations:
    name: (v) -> "can't be blank" unless v && v.length > 0
