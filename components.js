// Built-in Asteroid components.

// Components constructors are called with "new" when a document is added.
// They may optionally have the following methods:
//
// changed(fields)
//   changes have been pushed to the document
// advance(delta)
//   time has increased by delta seconds
// removed()
//   notification that document has been removed
//
// TODO: Add other methods, eg. beforeAdvance, afterAdvance.

Asteroid.Transform = function Transform(doc) {
  // We use separate pos and rot top-level attributes to increase
  // granularity of updates.
  if (doc.pos == null) {
    doc.pos = [0, 0, 0];
  }
  if (doc.rot == null) {
    doc.rot = 0;
  }
};
