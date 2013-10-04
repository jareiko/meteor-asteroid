
# Entity Component System

Asteroid = {}

Asteroid.entities = []

class Asteroid.Entity
  constructor: (name, collection, handlers) ->

    Asteroid.entities.push @

    # We maintain an in-memory cache of ents.
    ents = []
    entsById = {}

    # A list of subscriptions.
    # TODO: Move responsibility for publishing outside of Entity itself.
    subs = []

    addEnt = (ent) ->
      throw new Error 'missing _id' unless ent._id
      ents.push ent
      entsById[ent._id] = ent
      handlers.added?.call ent
      sub.added name, ent._id, ent for sub in subs
      return

    removeEnt = (_id) ->
      ent = entsById[_id]
      return unless ent
      handlers.removed?.call ent
      ents = _.filter ents, (e) -> e._id isnt _id
      delete entsById[_id]
      sub.removed name, _id for sub in subs
      return

    # For now we just grab everything.
    # This won't work once there are too many objects to fit in memory.
    dbEntsHandle = collection.find().observeChanges
      added: (_id, fields) ->
        ent = _.clone fields
        ent._id = _id
        addEnt ent
      changed: (_id, fields) ->
        # Have to be careful here, because changes may be out of date.
      removed: removeEnt

    # TODO: Periodically write data back to the DB.

    # TODO: Move responsibility for publishing outside of this class.
    Meteor.publish 'region', (x, y) ->
      # TODO: Region limiting.
      # Send the current in-memory ents, not the mongo ones.
      @added name, ent._id, ent for ent in ents
      @ready()
      subs.push @
      @onStop => subs = _.without subs, @
      return

    @tick = (delta) ->
      for ent in ents
        fields = _.result handlers, 'publish'
        oldState = fields and _.pick ent, fields

        handlers.update?.call ent, delta

        if oldState
          publish = {}
          for key, value of oldState
            publish[key] = ent[key] unless _.isEqual oldState[key], ent[key]

          unless _.isEmpty publish
            for sub in subs
              # TODO: Check that this ent is visible to this sub.
              sub.changed name, ent._id, publish

      # Clean up any destroyed ents.
      entsSnapshot = _.clone ents
      for ent in entsSnapshot
        if ent.destroyed
          removeEnt ent._id
          collection.remove { _id: ent._id }

      # TODO: Round-robin instead of random.
      # TODO: Ignore unchanged ents.
      ent = Random.choice ents
      fields = _.result handlers, 'persist'
      if fields
        persist = _.pick ent, fields
        unless _.isEmpty persist
          collection.update { _id: ent._id }, { $set: persist }

      return

Meteor.startup ->
  tick = (delta) ->
    for entity in Asteroid.entities
      entity.tick delta
    return

  delta = 0.1
  tickWithTraceback = (delta) ->
    try
      tick delta
    catch e
      console.error e.stack or e
    return

  Meteor.setInterval (tickWithTraceback.bind null, delta), delta * 1000
