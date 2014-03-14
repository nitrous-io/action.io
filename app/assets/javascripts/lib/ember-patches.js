// backported patches from newer versions of Ember

Ember.merge = function(original, updates) {
  for (var prop in updates) {
    if (!updates.hasOwnProperty(prop)) { continue; }
    original[prop] = updates[prop];
  }
  return original;
};
