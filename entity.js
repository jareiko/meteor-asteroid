Asteroid = {};

Asteroid.Entity = function Entity(doc, collection) {
  this.doc = doc;
  this.entComps = collection.components.map(function(component) {
    return new component(this);
  });
};

var proxyMethod = function(methodName) {
  return function() {
    this.entComps.forEach(function(entComp) {
      if (typeof entComp[methodName] === "function") {
        entComp[methodName].apply(entComp, arguments);
      }
    });
  };
};

Asteroid.Entity.prototype.changed = proxyMethod('changed');
Asteroid.Entity.prototype.removed = proxyMethod('removed');
Asteroid.Entity.prototype.advance = proxyMethod('advance');

Asteroid.Entity.prototype.getComponent = function(component) {
  return _.findWhere(this.entComps, {
    constructor: component
  }) || null;
};
