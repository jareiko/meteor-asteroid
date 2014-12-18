Asteroid.EntitySystem = function EntitySystem(fps) {
  fps = (typeof fps !== 'undefined') ? fps : 60;
  this.collections = [];

  // TODO: Make advancing configurable.
  if (Meteor.isServer) {
    //less floating point errors in calculations
    fps = ( 1000 / (fps * 1000));
    var that = this;
    var d = new Date();
    var lastTime = d.getTime();
    Meteor.setInterval(function() {
      lastTime = that.advance(lastTime);
    }, fps * 1000);
  }
};

Asteroid.EntitySystem.prototype.addEntityCollection = function(collection) {
  this.collections.push(collection);
};

Asteroid.EntitySystem.prototype.advance = function(lastTime) {
  var d = new Date();
  var thisTime = d.getTime();
  var delta = (thisTime - lastTime) / 1000;
  this.collections.forEach(function(collection) {
    collection.advance(delta);
  });
  return thisTime;
};