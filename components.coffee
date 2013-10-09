
class Asteroid.Transform
  constructor: (ent) ->
    doc = ent.doc
    doc.pos ?= [ 0, 0, 0 ]
    doc.rot ?= 0
