Asteroid.EntitySystem = function EntitySystem() {
  var delta;
  this.collections = [];

  // TODO: Make advancing configurable.
  if (Meteor.isServer) {
    delta = 0.1;
    var that = this;
    Meteor.setInterval(function() {
      that.advance(delta);
    }, delta * 1000);
  }
};

EntitySystem.prototype.addEntityCollection = function(collection) {
  this.collections.push(collection);
};

EntitySystem.prototype.advance = function(delta) {
  this.collections.each(function(collection) {
    collection.advance(delta);
  });
};
