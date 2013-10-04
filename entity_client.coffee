
Asteroid.entities = []

class Asteroid.Entity
  components = Asteroid.components

  constructor: (name, collection) ->
    Asteroid.entities.push @

    # We maintain an in-memory cache of ents.
    ents = []
    entsById = {}

    addEnt = (ent) ->
      ents.push ent
      entsById[ent._id] = ent
      ent.components ?= []
      for comp in ent.components
        components[comp]?.added?.call ent
      return

    removeEnt = (_id) ->
      ent = entsById[_id]
      return unless ent
      for comp in ent.components
        components[comp]?.removed?.call ent
      ents = _.filter ents, (e) -> e._id isnt _id
      delete entsById[_id]
      return

    dbEntsHandle = collection.find().observeChanges
      added: (_id, fields) ->
        ent = _.clone fields
        ent._id = _id
        addEnt ent
      changed: (_id, fields) ->
        ent = entsById[_id]
        _.extend ent, fields if ent
      removed: removeEnt

    @update = (delta) ->
      for ent in ents
        for comp in ent.components
          components[comp]?.update?.call ent, delta

      # Clean up any destroyed ents.
      entsSnapshot = _.clone ents
      for ent in entsSnapshot
        if ent.destroyed
          removeEnt ent._id
          collection.remove { _id: ent._id }
      return


Asteroid.update = (delta) ->
  for entity in Asteroid.entities
    entity.update delta
