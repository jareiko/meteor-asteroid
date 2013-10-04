
Asteroid = {}

Asteroid.components = {}

Asteroid.registerComponent = (name, methods) ->
  Asteroid.components[name] = methods

  # TODO: Check if we need to go back and do Start() calls on existing entities?
