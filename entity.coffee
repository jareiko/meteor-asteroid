
Asteroid.entities = []

class Asteroid.Entity
  components = Asteroid.components

  constructor: (name, collection, options) ->
    Asteroid.entities.push @

    # TODO: Combine publish & persist from current components.

    # Published fields are sent to clients.
    publishedFields = [ 'pos', 'components', 'plan' ]

    # Persisted fields are periodically written back to the DB.
    persistedFields = [ 'pos', 'components' ]

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
      ent.components ?= []
      for comp in ent.components
        components[comp]?.added?.call ent
      sub.added name, ent._id, ent for sub in subs
      return

    removeEnt = (_id) ->
      ent = entsById[_id]
      return unless ent
      for comp in ent.components
        components[comp]?.removed?.call ent
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
        return
      changed: (_id, fields) ->
        if Meteor.isClient
          # On the server, we assume that any DB changes were probably
          # caused by us at some point in the past, so we ignore them.
          ent = entsById[_id]
          _.extend ent, fields if ent
        return
      removed: removeEnt

    if Meteor.isServer
      # TODO: Move responsibility for publishing outside of this class.
      Meteor.publish 'region', (x, y) ->
        sub = @
        console.log "subscribe session: #{sub._session.id} user: #{sub.userId}"
        # TODO: Region limiting.
        sub.added name, ent._id, ent for ent in ents
        sub.ready()
        subs.push sub
        sub.onStop ->
          console.log "unsubscribe session: #{sub._session.id} user: #{sub.userId}"
          subs = _.without subs, sub
        return

    @update = (delta) ->
      if Meteor.isServer
        for ent in ents
          ent._old_state = JSON.parse JSON.stringify _.pick ent, publishedFields

      for ent in ents
        for comp in ent.components
          components[comp]?.update?.call ent, delta

      # for ent in ents
      #   for comp in ent.components
      #     components[comp]?.lateUpdate?.call ent, delta

      if Meteor.isServer
        for ent in ents
          publish = {}
          # TODO: Use Object.observe or similar instead of polling?
          for key, value of ent._old_state
            publish[key] = ent[key] unless _.isEqual ent._old_state[key], ent[key]

          unless _.isEmpty publish
            # Workaround: Meteor ignores changes if you don't clone the object.
            publish = JSON.parse JSON.stringify publish
            for sub in subs
              # TODO: Check that this ent is visible to this sub.
              sub.changed name, ent._id, publish

      # Clean up any destroyed ents.
      entsSnapshot = _.clone ents
      for ent in entsSnapshot
        if ent.destroyed
          removeEnt ent._id
          collection.remove { _id: ent._id }

      if Meteor.isServer
        # TODO: Round-robin instead of random.
        # TODO: Ignore unchanged ents.
        ent = Random.choice ents
        persist = _.pick ent, persistedFields
        unless _.isEmpty persist
          collection.update { _id: ent._id }, { $set: persist }
      return

Asteroid.update = (delta) ->
  for entity in Asteroid.entities
    entity.update delta

Meteor.startup ->
  if Meteor.isServer
    delta = 0.2
    Meteor.setInterval (-> Asteroid.update delta), delta * 1000
