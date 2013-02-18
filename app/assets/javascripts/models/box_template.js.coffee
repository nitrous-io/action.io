AIO.BoxTemplate = AIO.Model.extend
  name        : DS.attr('string')
  image       : DS.attr('string')
  description : DS.attr('string')
  enabled     : DS.attr('boolean')
  runtime     : DS.attr('string')
