Asteroid.Entity = function Entity(doc) {
  this.doc = doc;
  // Entries in this array correspond to the parent EntityCollection's
  // components array.
  this.entComps = [];
};

var proxyMethod = function(methodName) {
  this.entComps.each(function(entComp) {
    if (typeof entComp[methodName] === "function") {
      entComp[methodName].apply(entComp, arguments);
    }
  });
};

Entity.prototype.changed = proxyMethod('changed');
Entity.prototype.removed = proxyMethod('removed');
Entity.prototype.advance = proxyMethod('advance');

Entity.prototype.getComponent = function(component) {
  return _.findWhere(this.entComps, {
    constructor: component
  });
};
