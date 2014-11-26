// Built-in Asteroid components.

Asteroid.Transform = function Transform(ent) {
  var doc = ent.doc;
  if (doc.pos == null) {
    doc.pos = [0, 0, 0];
  }
  if (doc.rot == null) {
    doc.rot = 0;
  }
};
