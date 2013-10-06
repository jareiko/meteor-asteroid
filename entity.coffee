
Asteroid =
  entities: []

class EntitySystemAPI
  constructor: (@ent) ->
  componentData: (name) -> @ent[name]

class Asteroid.EntitySystem
  constructor: (@name) ->
    Asteroid.entities.push @

    # We maintain an in-memory cache of ents.
    @ents = []
    @entsById = {}

    # A list of subscriptions.
    # TODO: Move responsibility for publishing outside of EntitySystem.
    @subs = []

    # Registered components.
    @components = {}

    @collection = null

    if Meteor.isServer
      # TODO: Move responsibility for publishing outside of this class.
      that = @
      Meteor.publish 'region', (x, y) ->
        sub = @
        console.log "subscribe session: #{sub._session.id} user: #{sub.userId}"
        # TODO: Region limiting.
        sub.added name, ent._id, ent for ent in that.ents
        sub.ready()
        that.subs.push sub
        sub.onStop ->
          console.log "unsubscribe session: #{sub._session.id} user: #{sub.userId}"
          that.subs = _.without that.subs, sub
        return

    @defaultComponents = [ 'transform' ]

    @registerComponent 'transform',
      added: ->
        @pos ?= [ 0, 0, 0 ]
        @rot ?= 0
      publish: -> { @pos, @rot }

  _addEnt: (ent, initParams) ->
    throw new Error 'missing _id' unless ent._id
    @ents.push ent
    @entsById[ent._id] = ent
    for own field of ent
      @components[field]?.added?.call ent[field], new EntitySystemAPI(ent), initParams?[field]
    sub.added @name, ent._id, ent for sub in @subs
    return

  _removeEnt: (_id) ->
    ent = @entsById[_id]
    return unless ent
    for own field of ent
      @components[field]?.removed?.call ent[field], new EntitySystemAPI(ent)
    @ents = _.filter @ents, (e) -> e._id isnt _id
    delete @entsById[_id]
    sub.removed @name, _id for sub in @subs
    return

  advance: (delta) ->
    ents = @ents
    subs = @subs
    components = @components

    for ent in ents
      for own field of ent
        components[field]?.advance?.call ent[field], new EntitySystemAPI(ent), delta

    # for ent in ents
    #   for comp in ent.components
    #     components[comp]?.lateadvance?.call ent, delta

    # Clean up any destroyed ents.
    entsSnapshot = _.clone ents
    for ent in entsSnapshot
      if ent.destroyed
        removeEnt ent._id
        @collection.remove { _id: ent._id }

    # Publishing.
    if Meteor.isServer
      for ent in ents
        # TODO: More sophisticated rate limiting. :)
        # continue if Math.random() < 0.5

        publish = {}
        for own field of ent
          pub = components[field]?.publish?.call ent[field]
          publish[field] = pub if pub

        unless _.isEmpty publish
          # TODO: Maintain a cache and perform diffs?
          # It looks like Meteor is already doing this itself at the field level.

          # Workaround: Meteor seems to ignore changes unless you clone the object.
          publish = JSON.parse JSON.stringify publish

          for sub in subs
            # TODO: Check that this ent is visible to this sub.
            sub.changed @name, ent._id, publish

    # Persistence.
    if Meteor.isServer
      # TODO: Round-robin instead of random.
      # TODO: Ignore unchanged ents.
      ent = Random.choice ents
      @collection.update { _id: ent._id }, ent
    return

  registerComponent: (name, methods) ->
    @components[name] = methods
    for ent in @ents when ent[name]?
      methods.added?.call ent[name], new EntitySystemAPI(ent)
    return

  setCollection: (@collection) ->
    # For now we just grab everything.
    # This won't work once there are too many objects to fit in memory.
    handle = collection.find().observeChanges
      added: (_id, fields) =>
        ent = _.clone fields
        ent._id = _id
        @_addEnt ent
        return
      changed: (_id, fields) =>
        if Meteor.isClient
          # On the server, we assume that any DB changes were probably
          # caused by us at some point in the past, so we ignore them.
          ent = @entsById[_id]
          _.extend ent, fields if ent
        return
      removed: (_id) =>
        @_removeEnt _id
    return

  addEntity: (initParams) ->
    components = Object.keys initParams
    components = _.union components, @defaultComponents
    ent =
      _id: Random.id()
    for field in components
      ent[field] = {}
    @_addEnt ent, initParams
    @collection.insert ent
    ent

Asteroid.advance = (delta) ->
  for entity in Asteroid.entities
    entity.advance delta
  return

Meteor.startup ->
  if Meteor.isServer
    delta = 0.2
    Meteor.setInterval (-> Asteroid.advance delta), delta * 1000
