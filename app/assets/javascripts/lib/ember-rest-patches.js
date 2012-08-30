Em.Resource.reopen({
  findResource: function() {
    var self = this;

    return this._resourceRequest({type: 'GET'})
      .done(function(json) {
        self.deserialize(json[self.get('resourceName')] || {});
      });
  },

  saveResource: function() {
    var self = this;

    if (this.validate !== undefined) {
      var error = this.validate();
      if (error) {
        return {
          fail: function(f) { f(error); return this; },
          done: function() { return this; },
          always: function(f) { f(); return this; }
        };
      }
    }

    return this._resourceRequest({type: this.isNew() ? 'POST' : 'PUT',
                                  data: this.serialize()})
      .done(function(json) {
        // Update properties
        if (json) self.deserialize(json[self.get('resourceName')] || {});
      });
  },

  serialize: function() {
    var name = this.resourceName,
        props = this.resourceProperties,
        prop,
        ret = {};

    ret[name] = {};
    for(var i = 0; i < props.length; i++) {
      prop = props[i];
      if(serialized = this.serializeProperty(prop)) {
        ret[name][prop] = serialized;
      }
    }
    return ret;
  }
});

Em.ResourceController.reopen({
  findAll: function() {
    var self = this;

    return this._resourceRequest({type: 'GET'})
      .done(function(json) {
        self.clearAll();
        self.loadAll(json[self.get('jsonRoot')] || []);
      });
  }
});
